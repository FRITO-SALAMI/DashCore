enum DistanceUnit { kilometers, miles }

double fromKilometers(num value, DistanceUnit unit) =>
    unit == DistanceUnit.miles ? value / 1.609344 : value.toDouble();

double toKilometers(num value, DistanceUnit unit) =>
    unit == DistanceUnit.miles ? value * 1.609344 : value.toDouble();

String clockLabel(int hour, int minute, bool use24Hours) {
  final minutes = minute.toString().padLeft(2, '0');
  if (use24Hours) return '${hour.toString().padLeft(2, '0')}:$minutes';
  return '${hour % 12 == 0 ? 12 : hour % 12}:$minutes ${hour < 12 ? 'AM' : 'PM'}';
}
