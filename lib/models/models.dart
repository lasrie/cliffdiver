class LocationSuggestion {
  String label;
  String locationId;

  LocationSuggestion({this.label, this.locationId});

  @override
  String toString() {
    return label;
  }
}

class LocationResult {
  String label;
  String locationId;
  double latitude;
  double longitude;
  String resultType;
  var address;

  LocationResult(
      {this.label,
      this.locationId,
      this.latitude,
      this.longitude,
      this.resultType,
      this.address});

  @override
  String toString() {
    return label;
  }
}
