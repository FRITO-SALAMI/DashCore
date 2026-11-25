import '../providers/obd_provider.dart';

typedef _Send = Future<String> Function(String command);
typedef WorkshopFreezeFrame = ({int? rpm, int? speedKmh, int? coolantC});

class WorkshopReport {
  const WorkshopReport({
    required this.adapter,
    required this.mil,
    required this.notReady,
    required this.confirmed,
    required this.pending,
    required this.permanent,
    required this.supportedPids,
  });

  final String? adapter;
  final bool? mil;
  final int? notReady;
  final int? supportedPids;
  final Set<String>? confirmed, pending, permanent;
}

class WorkshopDiagnostics {
  const WorkshopDiagnostics(this.obd);
  final ObdProvider obd;

  Future<WorkshopReport> read({required bool Function() isActive}) =>
      obd.runWorkshopDiagnostic(_scan, isActive: isActive);

  Future<WorkshopFreezeFrame> readFreezeFrame({
    required bool Function() isActive,
  }) => obd.runWorkshopDiagnostic((send) async {
    List<int>? rpm, speed, coolant;
    try {
      rpm = _pid(await send('020C00'), 0x0C, 2, frame: 0);
      speed = _pid(await send('020D00'), 0x0D, 1, frame: 0);
      coolant = _pid(await send('020500'), 0x05, 1, frame: 0);
    } on StateError {
      // Some adapters cannot return all of the snapshots.
    }
    return (
      rpm: rpm == null ? null : ((rpm[0] << 8) + rpm[1]) ~/ 4,
      speedKmh: speed?.first,
      coolantC: coolant == null ? null : coolant.first - 40,
    );
  }, isActive: isActive);

  Future<WorkshopReport> clear({required bool Function() isActive}) =>
      obd.runWorkshopDiagnostic((send) async {
        final speeds = _pidFrames(await send('010D'), 0x0D, 1).toList();
        final rpms = _pidFrames(await send('010C'), 0x0C, 2).toList();
        if (speeds.isEmpty ||
            rpms.isEmpty ||
            speeds.any((value) => value[0] != 0) ||
            rpms.any((value) => value[0] != 0 || value[1] != 0)) {
          throw StateError(
            'Detén el vehículo, apaga el motor y deja el contacto encendido.',
          );
        }
        if (_payloads(await send('04'), 0x44).isEmpty) {
          throw StateError('La centralita no confirmó el borrado.');
        }
        return _scan(send);
      }, isActive: isActive);

  Future<WorkshopReport> _scan(_Send send) async {
    Set<String>? confirmed, pending, permanent;
    List<int>? status, supported;
    String? adapter;
    try {
      confirmed = _dtcs(await send('03'), 0x43);
      status = _pid(await send('0101'), 0x01, 4);
      pending = _dtcs(await send('07'), 0x47);
      permanent = _dtcs(await send('0A'), 0x4A);
      supported = _pid(await send('0100'), 0x00, 4);
      adapter = (await send('ATI'))
          .split(RegExp(r'[\r\n>]+'))
          .map((line) => line.trim())
          .where(
            (line) =>
                line.toUpperCase().contains('ELM') ||
                line.toUpperCase().startsWith('STN'),
          )
          .firstOrNull;
    } on StateError {
      // Keep data already returned, without sending after the channel has timed out.
    }
    final incomplete = status == null
        ? null
        : _bitCount(
            ((status[1] >> 4) & status[1] & 7) | ((status[2] & status[3]) << 3),
          );
    return WorkshopReport(
      adapter: adapter,
      mil: status == null ? null : status[0] & 0x80 != 0,
      notReady: incomplete,
      confirmed: confirmed,
      pending: pending,
      permanent: permanent,
      supportedPids: supported?.fold<int>(
        0,
        (int count, byte) => count + _bitCount(byte),
      ),
    );
  }

  static int _bitCount(int value) {
    var count = 0;
    for (var bits = value; bits != 0; bits &= bits - 1) {
      count++;
    }
    return count;
  }

  static List<int>? _pid(String raw, int pid, int width, {int? frame}) =>
      _pidFrames(raw, pid, width, frame: frame).firstOrNull;

  static Iterable<List<int>> _pidFrames(
    String raw,
    int pid,
    int width, {
    int? frame,
  }) sync* {
    final offset = frame == null ? 1 : 2;
    for (final data in _payloads(raw, frame == null ? 0x41 : 0x42)) {
      if (data.length >= width + offset &&
          data.first == pid &&
          (frame == null || data[1] == frame)) {
        yield data.sublist(offset, offset + width);
      }
    }
  }

  static Set<String>? _dtcs(String response, int mode) {
    final frames = _payloads(response, mode);
    if (frames.isEmpty) return null;
    final codes = <String>{};
    for (final frame in frames) {
      // Long-established protocols return pairs. CAN normally prefixes a count.
      final start = frame.length.isOdd ? 1 : 0;
      final end = start == 1
          ? (1 + 2 * frame.first).clamp(1, frame.length)
          : frame.length;
      for (var index = start; index + 1 < end; index += 2) {
        final a = frame[index], b = frame[index + 1];
        if (a == 0 && b == 0) continue;
        final digits = ((a & 0x0F) * 256 + b)
            .toRadixString(16)
            .padLeft(3, '0')
            .toUpperCase();
        codes.add('${'PCBU'[a >> 6]}${(a >> 4) & 3}$digits');
      }
    }
    return codes;
  }

  static List<List<int>> _payloads(String raw, int mode) {
    final frames = <List<int>>[];
    for (var line in raw.toUpperCase().split(RegExp(r'[\r\n>]+'))) {
      line = line.trim();
      if (line.startsWith('SEARCHING'))
        line = line.substring(9).replaceFirst(RegExp(r'^[.\s]+'), '');
      final joined = line
          .replaceFirst(RegExp(r'^[0-9A-F]{3}\s+'), '')
          .replaceAll(RegExp(r'\s+'), '');
      if (joined.length < 2 ||
          joined.length.isOdd ||
          !RegExp(r'^[0-9A-F]+$').hasMatch(joined))
        continue;
      final bytes = [
        for (var i = 0; i < joined.length; i += 2)
          int.parse(joined.substring(i, i + 2), radix: 16),
      ];
      if (bytes.first == mode) {
        frames.add(bytes.sublist(1));
      } else if (bytes.length >= 2 && bytes[0] <= 7 && bytes[1] == mode) {
        frames.add(bytes.sublist(2));
      }
    }
    return frames;
  }
}
