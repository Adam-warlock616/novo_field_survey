class SurveyModel {
  final String id;
  final String technicianId; // <--- 1. NEW FIELD
  final String customerName;
  final String address;
  final DateTime dateCreated;
  final String status;

  // Location Data
  final double latitude;
  final double longitude;

  // Roof Data
  final String roofPitch;
  final String azimuth;
  final double shading;

  // Electrical Data
  final String panelLocation;
  final int mainBreakerAmps;
  final bool isPanelUpgradable;

  SurveyModel({
    required this.id,
    required this.technicianId, // <--- 2. ADD TO CONSTRUCTOR
    required this.customerName,
    required this.address,
    required this.dateCreated,
    this.status = 'Draft',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.roofPitch = 'Unknown',
    this.azimuth = 'Unknown',
    this.shading = 0.0,
    this.panelLocation = 'Unknown',
    this.mainBreakerAmps = 0,
    this.isPanelUpgradable = true,
  });

  factory SurveyModel.fromMap(Map<String, dynamic> map, String id) {
    return SurveyModel(
      id: id,
      technicianId:
          map['technicianId'] ?? '', // <--- 3. READ IT (Default to empty)
      customerName: map['customerName'] ?? '',
      address: map['address'] ?? '',
      dateCreated: DateTime.parse(map['dateCreated']),
      status: map['status'] ?? 'Draft',

      // Safe Double Conversion
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),

      roofPitch: map['roofPitch'] ?? 'Unknown',
      azimuth: map['azimuth'] ?? 'Unknown',
      shading: (map['shading'] ?? 0.0).toDouble(),

      panelLocation: map['panelLocation'] ?? 'Unknown',
      mainBreakerAmps: map['mainBreakerAmps'] ?? 0,
      isPanelUpgradable: map['isPanelUpgradable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'technicianId': technicianId, // <--- 4. WRITE IT
      'customerName': customerName,
      'address': address,
      'dateCreated': dateCreated.toIso8601String(),
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'roofPitch': roofPitch,
      'azimuth': azimuth,
      'shading': shading,
      'panelLocation': panelLocation,
      'mainBreakerAmps': mainBreakerAmps,
      'isPanelUpgradable': isPanelUpgradable,
    };
  }

  SurveyModel copyWith({
    String? technicianId, // <--- 5. ADD TO COPYWITH
    String? customerName,
    String? address,
    String? status,
    double? latitude,
    double? longitude,
    String? roofPitch,
    String? azimuth,
    double? shading,
    String? panelLocation,
    int? mainBreakerAmps,
    bool? isPanelUpgradable,
  }) {
    return SurveyModel(
      id: id,
      technicianId: technicianId ?? this.technicianId,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      dateCreated: dateCreated,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      roofPitch: roofPitch ?? this.roofPitch,
      azimuth: azimuth ?? this.azimuth,
      shading: shading ?? this.shading,
      panelLocation: panelLocation ?? this.panelLocation,
      mainBreakerAmps: mainBreakerAmps ?? this.mainBreakerAmps,
      isPanelUpgradable: isPanelUpgradable ?? this.isPanelUpgradable,
    );
  }
}
