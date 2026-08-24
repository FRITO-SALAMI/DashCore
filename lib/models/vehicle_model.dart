class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String backgroundImage; // Path local o asset
  final String modelPath;       // Path local o asset
  final String? backgroundUrl;  // URL de Supabase
  final String? modelUrl;       // URL de Supabase
  final bool isDownloaded;

  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.backgroundImage,
    required this.modelPath,
    this.backgroundUrl,
    this.modelUrl,
    this.isDownloaded = false,
  });

  factory Vehicle.fromSupabase(Map<String, dynamic> data, {bool downloaded = false, String? localModel, String? localBg}) {
    return Vehicle(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      brand: data['brand'] ?? 'Unknown',
      backgroundImage: localBg ?? data['background_url'] ?? '',
      modelPath: localModel ?? data['model_url'] ?? '',
      backgroundUrl: data['background_url'],
      modelUrl: data['model_url'],
      isDownloaded: downloaded,
    );
  }

  Vehicle copyWith({
    String? backgroundImage,
    String? modelPath,
    bool? isDownloaded,
  }) {
    return Vehicle(
      id: id,
      name: name,
      brand: brand,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      modelPath: modelPath ?? this.modelPath,
      backgroundUrl: backgroundUrl,
      modelUrl: modelUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

// Estos vehículos se mantendrán como referencia o fallback si no hay internet
// Pero idealmente se cargarán desde Supabase.
final List<Vehicle> defaultVehicles = [
  const Vehicle(
    id: 'kia_optima_15',
    name: 'KIA OPTIMA 15',
    brand: 'KIA',
    backgroundImage: 'assets/images/png/kiaoptima15_bg.png',
    modelPath: 'assets/Models/Kia_Optima_15.glb',
    isDownloaded: true,
  ),
  const Vehicle(
    id: 'honda_civic_16',
    name: 'HONDA CIVIC 16',
    brand: 'HONDA',
    backgroundImage: 'assets/images/png/hondacivic16_bg.png',
    modelPath: 'assets/Models/Honda_Civic_16.glb',
    isDownloaded: true,
  ),
  const Vehicle(
    id: 'optima_2012',
    name: 'KIA OPTIMA (Legacy)',
    brand: 'KIA',
    backgroundImage: 'assets/images/png/Kiaoptima12_bg.png',
    modelPath: 'assets/Models/OPTIMA2012.glb',
    isDownloaded: true,
  ),
  const Vehicle(
    id: 'nissan_h1',
    name: 'NISSAN H1',
    brand: 'NISSAN',
    backgroundImage: 'assets/images/png/Nissanh1_bg.png',
    modelPath: 'assets/Models/nissan_h1.glb',
    isDownloaded: true,
  ),
  const Vehicle(
    id: 'sonata_rise',
    name: 'SONATA NRISE',
    brand: 'HYUNDAI',
    backgroundImage: 'assets/images/png/sonatanrise_bg.png',
    modelPath: 'assets/Models/Sonata_nrise.glb',
    isDownloaded: true,
  ),
  const Vehicle(
    id: 'sonata_y20',
    name: 'SONATA Y20',
    brand: 'HYUNDAI',
    backgroundImage: 'assets/images/png/sonatay20_bg.png',
    modelPath: 'assets/Models/Sonata_y20.glb',
    isDownloaded: true,
  ),
  const Vehicle(
    id: 'sonata_lf',
    name: 'SONATA LF',
    brand: 'HYUNDAI',
    backgroundImage: 'assets/images/png/sonatalf_bg.png',
    modelPath: 'assets/Models/Sonatalf.glb',
    isDownloaded: true,
  ),
  const Vehicle(
    id: 'honda_fit_16',
    name: 'HONDA FIT 16',
    brand: 'HONDA',
    backgroundImage: 'assets/images/png/hondafit16_bg.png',
    modelPath: 'assets/Models/Honda_Fit_16.glb',
    isDownloaded: true,
  ),
];
