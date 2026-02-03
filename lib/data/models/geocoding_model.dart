class GeocodingResult {
  final double lat;
  final double lng;
  final String formattedAddress;
  final String? placeId;

  GeocodingResult({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    this.placeId,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return GeocodingResult(
      lat: location['lat'],
      lng: location['lng'],
      formattedAddress: json['formatted_address'],
      placeId: json['place_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'formatted_address': formattedAddress,
      'place_id': placeId,
    };
  }

  @override
  String toString() {
    return 'GeocodingResult(lat: $lat, lng: $lng, address: $formattedAddress)';
  }
}
