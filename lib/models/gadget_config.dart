class GadgetConfig {
  final String id;
  final String label;
  double relativeX;
  double relativeY;
  double relativeWidth;
  double relativeHeight;
  int zIndex;
  String? imagePath;
  bool visible;
  bool locked;
  double fontScale;
  String fontFamily;

  GadgetConfig({
    required this.id,
    required this.label,
    required this.relativeX,
    required this.relativeY,
    required this.relativeWidth,
    required this.relativeHeight,
    this.zIndex = 0,
    this.imagePath,
    this.visible = true,
    this.locked = false,
    this.fontScale = 1.0,
    this.fontFamily = 'Inter',
  });

  GadgetConfig copyWith({
    double? relativeX,
    double? relativeY,
    double? relativeWidth,
    double? relativeHeight,
    int? zIndex,
    String? imagePath,
    bool? visible,
    bool? locked,
    double? fontScale,
    String? fontFamily,
  }) {
    return GadgetConfig(
      id: id,
      label: label,
      relativeX: relativeX ?? this.relativeX,
      relativeY: relativeY ?? this.relativeY,
      relativeWidth: relativeWidth ?? this.relativeWidth,
      relativeHeight: relativeHeight ?? this.relativeHeight,
      zIndex: zIndex ?? this.zIndex,
      imagePath: imagePath ?? this.imagePath,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      fontScale: fontScale ?? this.fontScale,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'relativeX': relativeX,
    'relativeY': relativeY,
    'relativeWidth': relativeWidth,
    'relativeHeight': relativeHeight,
    'zIndex': zIndex,
    'imagePath': imagePath,
    'visible': visible,
    'locked': locked,
    'fontScale': fontScale,
    'fontFamily': fontFamily,
  };

  factory GadgetConfig.fromJson(Map<String, dynamic> json) => GadgetConfig(
    id: json['id'] as String,
    label: json['label'] as String,
    relativeX: (json['relativeX'] as num).toDouble(),
    relativeY: (json['relativeY'] as num).toDouble(),
    relativeWidth: (json['relativeWidth'] as num).toDouble(),
    relativeHeight: (json['relativeHeight'] as num).toDouble(),
    zIndex: json['zIndex'] as int? ?? 0,
    imagePath: json['imagePath'] as String?,
    visible: json['visible'] as bool? ?? true,
    locked: json['locked'] as bool? ?? false,
    fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
    fontFamily: json['fontFamily'] as String? ?? 'Inter',
  );
}
