class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String? year;
  final String? engine;
  final String backgroundImage;
  final String modelPath;
  final String? backgroundUrl;
  final String? modelUrl;
  final bool isDownloaded;

  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    this.year,
    this.engine,
    required this.backgroundImage,
    required this.modelPath,
    this.backgroundUrl,
    this.modelUrl,
    this.isDownloaded = false,
  });

  factory Vehicle.fromSupabase(
    Map<String, dynamic> data, {
    bool downloaded = false,
    String? localModel,
    String? localBg,
  }) {
    return Vehicle(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? 'Unknown',
      brand: data['brand'] ?? 'Unknown',
      year: data['version']?.toString(), // Map 'version' from DB to year/version
      engine: data['engine']?.toString(),
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
    String? year,
    String? engine,
  }) {
    return Vehicle(
      id: id,
      name: name,
      brand: brand,
      year: year ?? this.year,
      engine: engine ?? this.engine,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      modelPath: modelPath ?? this.modelPath,
      backgroundUrl: backgroundUrl,
      modelUrl: modelUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
