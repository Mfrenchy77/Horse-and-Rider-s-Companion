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

  /// Empty user which represents an unauthenticated user.
  static const empty = User(id: '', name: '', email: '');

  /// Convenience getter to determine whether the current user is empty.
  bool get isEmpty => this == User.empty;

  /// Convenience getter to determine whether the current user is not empty.
  bool get isNotEmpty => this != User.empty;

  /// Converts the user to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
      'emailVerfified': emailVerified,
      'isGuest': isGuest,
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
    );
  }

  @override
  List<Object?> get props => [email, id, name, photo, emailVerified];
}
