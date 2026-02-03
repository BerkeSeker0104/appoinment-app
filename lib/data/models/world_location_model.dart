class CountryModel {
  final int id;
  final String rewrite;
  final String name;
  final String code;

  CountryModel({
    required this.id,
    required this.rewrite,
    required this.name,
    required this.code,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] ?? 0,
      rewrite: json['rewrite'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'rewrite': rewrite, 'name': name, 'code': code};
  }

  @override
  String toString() {
    return 'CountryModel(id: $id, name: $name, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CityModel {
  final int id;
  final int countryId;
  final String name;

  CityModel({required this.id, required this.countryId, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] ?? 0,
      countryId: json['country_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'country_id': countryId, 'name': name};
  }

  @override
  String toString() {
    return 'CityModel(id: $id, countryId: $countryId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class StateModel {
  final int id;
  final int citiesId;
  final String name;

  StateModel({required this.id, required this.citiesId, required this.name});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'] ?? 0,
      citiesId: json['cities_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'cities_id': citiesId, 'name': name};
  }

  @override
  String toString() {
    return 'StateModel(id: $id, citiesId: $citiesId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class WorldLocationResponse<T> {
  final bool status;
  final List<T> data;
  final WorldLocationPagination pagination;

  WorldLocationResponse({
    required this.status,
    required this.data,
    required this.pagination,
  });

  factory WorldLocationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return WorldLocationResponse<T>(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: WorldLocationPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class WorldLocationPagination {
  final int totalCount;
  final int pageLastCount;
  final int currentPage;
  final int dataCount;

  WorldLocationPagination({
    required this.totalCount,
    required this.pageLastCount,
    required this.currentPage,
    required this.dataCount,
  });

  factory WorldLocationPagination.fromJson(Map<String, dynamic> json) {
    return WorldLocationPagination(
      totalCount: json['totalCount'] ?? 0,
      pageLastCount: json['pageLastCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      dataCount: json['dataCount'] ?? 0,
    );
  }
}
