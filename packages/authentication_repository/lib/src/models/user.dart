import 'package:equatable/equatable.dart';

/// {@template user}
/// User model
///
/// [User.empty] represents an unauthenticated user.
/// {@endtemplate}
class User extends Equatable {
  /// {@macro user}
  const User({
    this.photo,
    required this.id,
    required this.name,
    required this.email,
    this.isGuest = true,
    this.emailVerified = false,
    this.isAdmin = false,
    this.isModerator = false,
    this.isEditor = false,
  });

  /// The current user's id.
  final String id;

  /// The current user's name (display name).
  final String name;

  /// The current user's email address.
  final String email;

  /// Url for the current user's photo.
  final String? photo;

  /// Whether the current user's email address has been verified.
  final bool emailVerified;

  /// Whether the current user is a guest.
  final bool isGuest;

  /// Whether the Firebase Auth token includes the `admin: true` custom claim.
  final bool isAdmin;

  /// Whether the Firebase Auth token includes the `moderator: true` custom
  /// claim.
  final bool isModerator;

  /// Whether the Firebase Auth token includes the `editor: true` custom claim.
  final bool isEditor;

  /// Whether this authenticated, email-verified user can access Administration.
  bool get canAccessAdministration =>
      !isGuest && emailVerified && (isAdmin || isModerator);

  /// Empty user which represents an unauthenticated user.
  static const empty = User(id: '', name: '', email: '');

  /// Convenience getter to determine whether the current user is empty.
  bool get isEmpty => this == User.empty;

  /// Convenience getter to determine whether the current user is not empty.
  bool get isNotEmpty => this != User.empty;

  /// Returns a copy of this [User] with the provided fields updated.
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photo,
    bool? emailVerified,
    bool? isGuest,
    bool? isAdmin,
    bool? isModerator,
    bool? isEditor,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      emailVerified: emailVerified ?? this.emailVerified,
      isGuest: isGuest ?? this.isGuest,
      isAdmin: isAdmin ?? this.isAdmin,
      isModerator: isModerator ?? this.isModerator,
      isEditor: isEditor ?? this.isEditor,
    );
  }

  /// Converts the user to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
      'emailVerfified': emailVerified,
      'isGuest': isGuest,
      'isAdmin': isAdmin,
      'isModerator': isModerator,
      'isEditor': isEditor,
    };
  }

  /// Creates a new user from a json object
  // ignore: sort_constructors_first
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photo: json['photo'] as String?,
      emailVerified: json['emailVerfified'] as bool,
      isGuest: json['isGuest'] as bool,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isModerator: json['isModerator'] as bool? ?? false,
      isEditor: json['isEditor'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        email,
        id,
        name,
        photo,
        emailVerified,
        isGuest,
        isAdmin,
        isModerator,
        isEditor,
      ];
}
