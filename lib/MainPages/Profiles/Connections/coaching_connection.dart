/// Backend-neutral domain model representing a coaching or horse-sharing
/// connection between a coach and a learner.
class CoachingConnection {
  CoachingConnection(this.id, Map<String, dynamic> data, {DateTime? updatedAt})
    : version = data['version'] as String,
      kind = data['kind'] as String,
      status = data['status'] as String,
      sender = data['sender'] as String,
      recipient = data['recipient'] as String,
      learner = data['learner'] as String,
      coach = data['coach'] as String,
      learnerName = data['learnerName'] as String,
      coachName = data['coachName'] as String,
      horseId = data['horseId'] as String?,
      horseName = data['horseName'] as String?,
      ownershipVersion = data['ownershipVersion'] as String?,
      updatedAt = updatedAt ?? _parseDate(data['updatedAt']);

  final String id;
  final String version;
  final String kind;
  final String status;
  final String sender;
  final String recipient;
  final String learner;
  final String coach;
  final String learnerName;
  final String coachName;
  final String? horseId;
  final String? horseName;
  final String? ownershipVersion;
  final DateTime? updatedAt;

  String otherName(String viewer) => viewer == coach ? learnerName : coachName;
  String get requesterName => sender == coach ? coachName : learnerName;

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
