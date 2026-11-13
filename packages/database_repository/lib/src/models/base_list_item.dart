// ignore_for_file: sort_constructors_first

import 'package:database_repository/src/models/rider_log_details.dart';

/// This is a multi use container. It is used to represent a Rating for a
/// Resource, a Log Entry for Horse or Rider, an Instructor Request, a Contact
/// for adding to a users Profile.
class BaseListItem {
  /// Constructor for a BaseListItem
  BaseListItem({
    this.name,
    this.date,
    this.extra,
    this.depth,
    this.message,
    this.id = '',
    this.imageUrl,
    this.parentId,
    this.isSelected,
    this.isCollapsed,
    this.riderLog,
  });

  /// Not sure what this is used for
  int? depth;

  /// If BaseListItem is for a Log Entry, this is the date of the log entry
  DateTime? date;

  /// If BaseListItem is a Rating, this is the users email who rated the
  /// resource.
  ///
  /// If it is a Log Entry, this is the date of the log entry.
  ///
  /// If it is a Instructor Request, this is the user making the request's
  /// email.
  ///
  /// If it is a Student Horse Request, this is the Horse's Id.
  ///
  /// If it is a Contact, this is the contact's email.
  final String? id;

  /// If BaseListItem is a Log Entry, this is the Users Name who made the log
  /// entry.
  ///
  /// If it is a Student Horse Request, this is the Horse Owner's Name.
  String? message;

  /// If the BaseListItem is a Log Entry, this is the Tag
  ///
  /// If the BaseListItem is an Instructor Request, this is the users pic url.
  ///
  /// If the BaseListItem is a Student Horse Request, this is the Horse's Pic
  /// url Thumbnail.
  ///
  /// If it is a Contact, this is the contact's thumbnail url.
  String? imageUrl;

  /// If BaseListItem is a Log Entry, this is the users email.
  ///
  /// If it is a Student Horse Request, this is the Horse Owner's email.
  String? parentId;

  /// If BaseListItem is a Rating, this is used to notate a positive rating.
  ///
  /// If it is a Instructor Request, this is used to notate if the request
  /// has been accepted or not.
  ///
  /// If it is a Student Horse Request, this is used to notate if the request
  /// has been accepted or not.
  bool? isSelected;

  /// If BaseListItem is a Rating, this is used to notate a negative rating.
  ///
  /// If it is a Instructor Request, this is used to notate if the request
  /// is for a Horse or a Rider. True if Rider, False if Horse.
  ///
  /// If it is a Student Horse Request, this is used to notate if the request
  /// is for a Horse or a Rider. True if Rider, False if Horse.
  ///
  /// Contact, this is used to notate if the contact is a Horse or a Rider.
  /// True if Rider, False if Horse.
  bool? isCollapsed;

  /// If BaseListItem is a Log Entry, this is used to hold the log entry
  /// message.
  ///
  /// If it is a Instructor Request, this is used to hold the name of the user
  /// making the request.
  ///
  /// If it is a Student Horse Request, this is used to hold the name of the
  /// Horse.
  ///
  /// If it is a Contact, this is used to hold the contact's name.
  final String? name;

  /// If the BaseListItem is a Student Horse Request, this is used to hold
  /// the requestors email.
  final String? extra;

  /// Structured fields for rider journal entries.
  final RiderLogDetails? riderLog;

  /// Uses the structured category or maps the old log tag.
  RiderLogType get riderLogType =>
      riderLog?.type ??
      switch (imageUrl) {
        'LogTag.Training' => RiderLogType.training,
        'LogTag.Show' => RiderLogType.show,
        'LogTag.Health' => RiderLogType.care,
        'LogTag.Edit' => RiderLogType.activity,
        _ => RiderLogType.reflection,
      };

  /// Checks that this is a journal entry attributed to the given rider.
  bool canEditRiderLog(String email) =>
      (id?.isNotEmpty ?? false) &&
      riderLogType != RiderLogType.activity &&
      email.isNotEmpty &&
      parentId?.toLowerCase() == email.toLowerCase();

  /// Creates a [BaseListItem] from a backend-neutral map.
  factory BaseListItem.fromMap(Map<String, dynamic> data) => BaseListItem(
    id: data['id'] as String?,
    riderLog: RiderLogDetails.fromMap(data['riderLog']),
    depth: data['depth'] as int?,
    name: data['name'] as String?,
    extra: data['extra'] as String?,
    message: data['message'] as String?,
    parentId: data['parentId'] as String?,
    isSelected: data['isSelected'] as bool?,
    imageUrl: data['imageUrl'] as String?,
    isCollapsed: data['isCollapsed'] as bool?,
    date: _parseDateTime(data['date']),
  );

  /// Creates a [BaseListItem] from a json map.
  factory BaseListItem.fromJson(Map<String, dynamic> json) =>
      BaseListItem.fromMap(json);

  /// Converts this [BaseListItem] to a backend-neutral map.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (riderLog != null) 'riderLog': riderLog!.toMap(),
      if (name != null) 'name': name,
      if (date != null) 'date': date!.toIso8601String(),
      if (depth != null) 'depth': depth,
      if (extra != null) 'extra': extra,
      if (message != null) 'message': message,
      if (parentId != null) 'parentId': parentId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (isSelected != null) 'isSelected': isSelected,
      if (isCollapsed != null) 'isCollapsed': isCollapsed,
    };
  }

  /// Converts this [BaseListItem] to a json map.
  Map<String, Object?> toJson() => toMap();

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
