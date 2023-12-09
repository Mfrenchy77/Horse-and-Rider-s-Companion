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
    this.isGuest = false,
    this.emailVerfified = false,
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
  final bool emailVerfified;

  /// Whether the current user is a guest.
  final bool isGuest;

  /// Empty user which represents an unauthenticated user.
  static const empty = User(id: '', name: '', email: '');

  /// Convenience getter to determine whether the current user is empty.
  bool get isEmpty => this == User.empty;

  /// Convenience getter to determine whether the current user is not empty.
  bool get isNotEmpty => this != User.empty;

  @override
  List<Object?> get props => [email, id, name, photo, emailVerfified];
}
