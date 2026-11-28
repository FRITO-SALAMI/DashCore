import '../models/vehicle_model.dart';

String vehicleShape(Vehicle? vehicle, [String source = '']) {
  final text =
      '${vehicle?.brand} ${vehicle?.name} ${vehicle?.year} ${vehicle?.modelUrl} ${vehicle?.modelPath} $source'
          .toLowerCase();
  if (RegExp(r'(^|[^a-z0-9])h1([^a-z0-9]|$)').hasMatch(text) ||
      text.contains('nissan_h1'))
    return 'h1';
  if (text.contains('civic')) return 'civic';
  if (text.contains('optima') || text.contains('k5')) {
    return text.contains('2012') ||
            text.contains('k5') ||
            text.contains('optima2012')
        ? 'k5_2012'
        : 'optima_2015';
  }
  if (text.contains('sonata')) {
    if (text.contains('y20') || text.contains('yf')) return 'sonata_y20';
    if (text.contains('n line') ||
        text.contains('nline') ||
        text.contains('nrise'))
      return 'sonata_n';
    return 'sonata_lf';
  }
  return 'generic';
}

String vehicleDisplayName(Vehicle vehicle) {
  return switch (vehicleShape(vehicle)) {
    'k5_2012' => 'Kia K5 / Optima TF · 2012',
    'optima_2015' => 'Kia Optima · 2015',
    'sonata_lf' => 'Hyundai Sonata LF',
    'sonata_n' => 'Hyundai Sonata N Line',
    'sonata_y20' => 'Hyundai Sonata Y20 / YF',
    'civic' => 'Honda Civic · 2016',
    'h1' => 'Hyundai H1',
    _ =>
      vehicle.id == 'local-generic'
          ? 'Deportivo genérico'
          : '${vehicle.brand} ${vehicle.name} ${vehicle.year ?? ''}'.trim(),
  };
}

List<Vehicle> uniqueVehicleChoices(
  List<Vehicle> local,
  List<Vehicle> catalog,
  Vehicle? selected,
) {
  final choices = <String, Vehicle>{};
  String key(Vehicle v) => v.isCustom
      ? v.id
      : vehicleShape(v) == 'generic'
      ? v.id
      : vehicleShape(v);
  for (final v in [...local, ...catalog]) {
    choices[key(v)] = v;
  }
  if (selected != null) choices[key(selected)] = selected;
  return choices.values.toList();
}
