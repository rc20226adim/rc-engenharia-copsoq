class Company {
  final String id;
  final String name;
  final String cnpj;
  final String city;
  final String state;
  final String sector;
  final DateTime createdAt;
  bool isActive;

  Company({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.city,
    required this.state,
    required this.sector,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'cnpj': cnpj,
    'city': city,
    'state': state,
    'sector': sector,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  Company copyWith({
    String? id,
    String? name,
    String? cnpj,
    String? city,
    String? state,
    String? sector,
    DateTime? createdAt,
    bool? isActive,
  }) =>
      Company(
        id: id ?? this.id,
        name: name ?? this.name,
        cnpj: cnpj ?? this.cnpj,
        city: city ?? this.city,
        state: state ?? this.state,
        sector: sector ?? this.sector,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );

  // Construtor para Hive/local (1 parâmetro)
  factory Company.fromMap(Map<String, dynamic> map, [String? docId]) => Company(
    id: docId ?? map['id'] ?? '',
    name: map['name'] ?? '',
    cnpj: map['cnpj'] ?? '',
    city: map['city'] ?? '',
    state: map['state'] ?? '',
    sector: map['sector'] ?? '',
    createdAt: map['createdAt'] is DateTime
        ? (map['createdAt'] as DateTime)
        : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    isActive: map['isActive'] ?? true,
  );
}
