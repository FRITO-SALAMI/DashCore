class ObdData {
  final int rpm;
  final int speed;
  final int engineTemp;
  final double voltage;

  const ObdData({
    this.rpm = 0,
    this.speed = 0,
    this.engineTemp = 0,
    this.voltage = 0.0,
  });

  ObdData copyWith({int? rpm, int? speed, int? engineTemp, double? voltage}) {
    return ObdData(
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      engineTemp: engineTemp ?? this.engineTemp,
      voltage: voltage ?? this.voltage,
    );
  }

  @override
  String toString() {
    return 'ObdData(rpm: $rpm, speed: $speed km/h, temp: $engineTemp°C, voltage: $voltage V)';
  }
}
