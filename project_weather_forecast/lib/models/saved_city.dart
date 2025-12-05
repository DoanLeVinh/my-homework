class SavedCity {
  final String name;
  final String displayName;
  final String country;
  final double lat;
  final double lon;
  final DateTime savedAt;

  SavedCity({
    required this.name,
    required this.displayName,
    required this.country,
    required this.lat,
    required this.lon,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'country': country,
      'lat': lat,
      'lon': lon,
      'savedAt': savedAt.millisecondsSinceEpoch,
    };
  }

  factory SavedCity.fromJson(Map<String, dynamic> json) {
    return SavedCity(
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      country: json['country'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(json['savedAt'] ?? 0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedCity && other.lat == lat && other.lon == lon;
  }

  @override
  int get hashCode => lat.hashCode ^ lon.hashCode;
}
