class ObdData {
  final int rpm;
  final int speed;
  final int engineTemp;
  final double voltage;
  final int fuelLevel;
  final int odometer;
  final String gear;

  const ObdData({
    this.rpm = 0,
    this.speed = 0,
    this.engineTemp = 0,
    this.voltage = 0.0,
    this.fuelLevel = 0,
    this.odometer = 0,
    this.gear = 'P',
  });

  ObdData copyWith({
    int? rpm,
    int? speed,
    int? engineTemp,
    double? voltage,
    int? fuelLevel,
    int? odometer,
    String? gear,
  }) {
    return ObdData(
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      engineTemp: engineTemp ?? this.engineTemp,
      voltage: voltage ?? this.voltage,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      odometer: odometer ?? this.odometer,
      gear: gear ?? this.gear,
    );
  }

  @override
  String toString() {
    return 'ObdData(rpm: $rpm, speed: $speed km/h, temp: $engineTemp°C, voltage: $voltage V, fuel: $fuelLevel%, odo: $odometer, gear: $gear)';
  }
}
