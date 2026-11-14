import 'dart:async';
import 'dart:convert';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horseandriderscompanion/Initialization/firebase_emulators.dart';
import 'package:http/http.dart' as http;

/// Cloud Function-backed implementation of [AccountDeletionRepository].
class FirebaseAccountDeletionRepository implements AccountDeletionRepository {
  FirebaseAccountDeletionRepository({
    required AuthGateway authGateway,
    String? projectId,
    http.Client? httpClient,
  }) : _authGateway = authGateway,
       _projectId = projectId,
       _httpClient = httpClient;

  final AuthGateway _authGateway;
  final String? _projectId;
  final http.Client? _httpClient;

  @override
  Future<AccountDeletionResult> deleteCurrentAccount() async {
    final token = await _authGateway.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AccountDeletionFailure(
        'Sign in again before deleting your account.',
      );
    }

    final project = _projectId ?? FirebaseAuth.instance.app.options.projectId;
    final endpoint = FirebaseEmulators.enabled
        ? FirebaseEmulators.accountDeletionEndpoint()
        : Uri.https(
            'us-central1-$project.cloudfunctions.net',
            '/requestAccountDeletion',
          );

    final client = _httpClient ?? http.Client();
    final ownsClient = _httpClient == null;
    try {
      final response = await client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'data': <String, Object?>{}}),
          )
          .timeout(const Duration(seconds: 30));

      final Object? body;
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        throw AccountDeletionFailure(
          response.statusCode == 404
              ? 'Account deletion service is unavailable.'
              : 'Account deletion returned an unexpected response.',
        );
      }

      if (body is Map) {
        final result = body['result'];
        if (result is Map) {
          final status = result['status'];
          if (status == 'scheduled') {
            return const AccountDeletionResult(
              status: AccountDeletionStatus.scheduled,
              message:
                  'Your account deletion is scheduled and will finish shortly.',
            );
          }
          return const AccountDeletionResult(
            status: AccountDeletionStatus.completed,
            message: 'Account Deleted',
          );
        }

        final error = body['error'];
        if (error is Map) {
          final details = error['details'];
          final detailsCode =
              details is Map ? details['code'] as String? : null;
          final message = error['message'] as String?;
          if (detailsCode == 'requires-recent-login') {
            return AccountDeletionResult(
              status: AccountDeletionStatus.requiresRecentLogin,
              message:
                  message ??
                  'Please reauthenticate before deleting your account.',
            );
          }
          if (message != null && message.isNotEmpty) {
            throw AccountDeletionFailure(message);
          }
        }
      }

      throw const AccountDeletionFailure();
    } on http.ClientException {
      throw const AccountDeletionFailure(
        'Could not reach the account deletion service.',
      );
    } on TimeoutException {
      throw const AccountDeletionFailure(
        'The account deletion request timed out. Please try again.',
      );
    } finally {
      if (ownsClient) client.close();
    }
  }
}
