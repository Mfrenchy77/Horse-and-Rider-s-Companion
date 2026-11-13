// ignore_for_file: sort_constructors_first, public_member_api_docs

///  Model of category
class Catagorry {
  Catagorry({
    required this.id,
    required this.name,
    required this.rider,
    required this.position,
    required this.lastEditBy,
    required this.description,
    required this.lastEditDate,
  });

  final String id;
  final String name;
  final bool rider;
  final int position;
  final String lastEditBy;
  final String description;
  final DateTime lastEditDate;

  factory Catagorry.fromMap(Map<String, dynamic> data) {
    return Catagorry(
      id: data['id'] as String,
      name: data['name'] as String,
      rider: data['rider'] as bool,
      position: data['position'] as int,
      lastEditBy: data['lastEditBy'] as String,
      description: data['description'] as String,
      lastEditDate: _parseDateTime(data['lastEditDate']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'rider': rider,
      'position': position,
      'lastEditBy': lastEditBy,
      'description': description,
      'lastEditDate': lastEditDate.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw ArgumentError('Expected DateTime, String, or int, got $value');
  }
}
