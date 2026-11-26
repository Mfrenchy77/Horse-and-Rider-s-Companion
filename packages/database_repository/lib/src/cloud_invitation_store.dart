// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:database_repository/src/invitation_store.dart';
import 'package:database_repository/src/models/invitation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;

/// Cloud Functions-backed [InvitationStore].
class CloudInvitationStore implements InvitationStore {
  /// Creates a [CloudInvitationStore].
  CloudInvitationStore({
    firebase_auth.FirebaseAuth? auth,
    http.Client? httpClient,
    Future<String?> Function()? tokenProvider,
    Uri? previewEndpoint,
    Uri? createEndpoint,
    Uri? redeemEndpoint,
    Uri? listEndpoint,
    Uri? revokeEndpoint,
    String? projectId,
  }) : _auth = auth,
       _httpClient = httpClient ?? http.Client(),
       _tokenProvider = tokenProvider,
       _previewEndpoint = previewEndpoint,
       _createEndpoint = createEndpoint,
       _redeemEndpoint = redeemEndpoint,
       _listEndpoint = listEndpoint,
       _revokeEndpoint = revokeEndpoint,
       _projectId = projectId;

  final firebase_auth.FirebaseAuth? _auth;
  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;
  final Uri? _previewEndpoint;
  final Uri? _createEndpoint;
  final Uri? _redeemEndpoint;
  final Uri? _listEndpoint;
  final Uri? _revokeEndpoint;
  final String? _projectId;

  Uri _resolveEndpoint(Uri? override, String functionName) {
    if (override != null) return override;
    final auth = _auth ?? firebase_auth.FirebaseAuth.instance;
    final project = _projectId ?? auth.app.options.projectId;
    return Uri.https(
      'us-central1-$project.cloudfunctions.net',
      '/$functionName',
    );
  }

  Future<String?> _readOptionalToken() async {
    if (_tokenProvider != null) {
      return _tokenProvider();
    }
    try {
      final auth = _auth ?? firebase_auth.FirebaseAuth.instance;
      return await auth.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _callFunction(
    Uri endpoint,
    Map<String, dynamic> data, {
    required bool requireAuth,
  }) async {
    final token = await _readOptionalToken();
    if (requireAuth && (token == null || token.isEmpty)) {
      throw const InvitationException(
        'Sign in with a verified email first.',
        code: 'unauthenticated',
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final http.Response response;
    try {
      response = await _httpClient
          .post(endpoint, headers: headers, body: jsonEncode({'data': data}))
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const InvitationException(
        'The invitation service timed out. Please try again.',
        code: 'deadline-exceeded',
      );
    } on http.ClientException {
      throw const InvitationException(
        'Unable to reach the invitation service. Check your connection and '
        'try again.',
        code: 'unavailable',
      );
    }

    var body = const <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {
      body = const <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = body['error'];
      final message = err is Map<String, dynamic>
          ? err['message'] as String? ?? 'Invitation request failed.'
          : 'Invitation request failed.';
      final code = err is Map<String, dynamic>
          ? err['status'] as String?
          : null;
      throw InvitationException(message, code: code);
    }

    final result = body['result'];
    if (result is Map<String, dynamic>) {
      return result;
    }
    return const <String, dynamic>{};
  }

  @override
  Future<InvitationPreview> getInvitationPreview(String token) async {
    final result = await _callFunction(
      _resolveEndpoint(_previewEndpoint, 'getInvitationPreview'),
      {'token': token},
      requireAuth: false,
    );
    return InvitationPreview.fromMap(result);
  }

  @override
  Future<InvitationCreateResult> createInvitation(
    InvitationCreateRequest request,
  ) async {
    final result = await _callFunction(
      _resolveEndpoint(_createEndpoint, 'createInvitation'),
      request.toMap(),
      requireAuth: true,
    );
    return InvitationCreateResult.fromMap(result);
  }

  @override
  Future<InvitationRedemptionResult> redeemInvitation(String token) async {
    final result = await _callFunction(
      _resolveEndpoint(_redeemEndpoint, 'redeemInvitation'),
      {'token': token},
      requireAuth: true,
    );
    return InvitationRedemptionResult.fromMap(result);
  }

  @override
  Future<List<InvitationRecord>> listMyInvitations() async {
    final result = await _callFunction(
      _resolveEndpoint(_listEndpoint, 'listMyInvitations'),
      const <String, dynamic>{},
      requireAuth: true,
    );
    final rawList = result['invitations'];
    if (rawList is! List) return const <InvitationRecord>[];
    return rawList
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => InvitationRecord.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<InvitationRecord> revokeInvitation(String invitationId) async {
    final result = await _callFunction(
      _resolveEndpoint(_revokeEndpoint, 'revokeInvitation'),
      {'invitationId': invitationId},
      requireAuth: true,
    );
    final raw = result['invitation'];
    return InvitationRecord.fromMap(
      raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{},
    );
  }
}
