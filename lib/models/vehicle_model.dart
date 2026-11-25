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
  final bool isCustom;
  final String? artworkPath;
  final String? rearArtworkPath;
  final String? paintColorHex;

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
    this.isCustom = false,
    this.artworkPath,
    this.rearArtworkPath,
    this.paintColorHex,
  });

  factory Vehicle.fromSupabase(
    Map<String, dynamic> data, {
    bool downloaded = false,
    String? localModel,
    String? localBg,
  }) {
    final id = data['id']?.toString() ?? '';
    final modelUrl = data['model_url']?.toString();

    return Vehicle(
      id: id,
      name: data['name'] ?? 'Unknown',
      brand: data['brand'] ?? 'Unknown',
      year: data['version']?.toString(), // Map 'version' from DB to year/version
      engine: data['engine']?.toString(),
      backgroundImage: localBg ?? data['background_url'] ?? '',
      modelPath: localModel ?? modelUrl ?? '',
      backgroundUrl: data['background_url'],
      modelUrl: modelUrl,
      isDownloaded: downloaded,
    );
  }

  Vehicle copyWith({
    String? backgroundImage,
    String? modelPath,
    bool? isDownloaded,
    String? year,
    String? engine,
    String? artworkPath,
    String? rearArtworkPath,
    String? paintColorHex,
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
      isCustom: isCustom,
      artworkPath: artworkPath ?? this.artworkPath,
      rearArtworkPath: rearArtworkPath ?? this.rearArtworkPath,
      paintColorHex: paintColorHex ?? this.paintColorHex,
    );
  }
}
