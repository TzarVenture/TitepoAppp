class CustomerAddress {
  final String id;
  final String name;
  final String phone;
  final String pincode;
  final String flatHouse;
  final String areaStreet;
  final String landmark;
  final String city;
  final String state;
  final String type; // 'Home', 'Work', 'Other'
  final bool isDefault;

  const CustomerAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.pincode,
    required this.flatHouse,
    required this.areaStreet,
    this.landmark = '',
    required this.city,
    required this.state,
    this.type = 'Home',
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [
      flatHouse,
      areaStreet,
      if (landmark.isNotEmpty) 'Near $landmark',
      '$city, $state - $pincode',
    ];
    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }

  CustomerAddress copyWith({
    String? id,
    String? name,
    String? phone,
    String? pincode,
    String? flatHouse,
    String? areaStreet,
    String? landmark,
    String? city,
    String? state,
    String? type,
    bool? isDefault,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pincode: pincode ?? this.pincode,
      flatHouse: flatHouse ?? this.flatHouse,
      areaStreet: areaStreet ?? this.areaStreet,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'pincode': pincode,
        'flatHouse': flatHouse,
        'areaStreet': areaStreet,
        'landmark': landmark,
        'city': city,
        'state': state,
        'type': type,
        'isDefault': isDefault,
      };

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      flatHouse: json['flatHouse'] as String? ?? '',
      areaStreet: json['areaStreet'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      type: json['type'] as String? ?? 'Home',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
