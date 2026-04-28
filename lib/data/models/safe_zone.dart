enum SafeZoneType { police, hospital, embassy, safeArea, landmark, unknown }

class SafeZone {
  const SafeZone({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.address,
    this.phone,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final SafeZoneType type;
  final double lat;
  final double lng;
  final String? address;
  final String? phone;
  final bool isVerified;

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final coordinates = location?['coordinates'] as List<dynamic>?;

    if (coordinates == null || coordinates.length < 2) {
      throw FormatException('SafeZone location.coordinates is required.');
    }

    return SafeZone(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Safe Zone').toString(),
      type: _parseType(json['type']?.toString()),
      lng: _toDouble(coordinates[0]),
      lat: _toDouble(coordinates[1]),
      address: _optionalString(json['address']),
      phone: _optionalString(json['phone']),
      isVerified: json['isVerified'] == true,
    );
  }

  static SafeZoneType _parseType(String? value) {
    switch (value) {
      case 'police':
        return SafeZoneType.police;
      case 'hospital':
        return SafeZoneType.hospital;
      case 'embassy':
        return SafeZoneType.embassy;
      case 'safe_area':
        return SafeZoneType.safeArea;
      case 'landmark':
        return SafeZoneType.landmark;
      default:
        return SafeZoneType.unknown;
    }
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Invalid coordinate value: $value');
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
