import 'dart:async';
import 'dart:convert';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Initialization/firebase_emulators.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/coaching_connection.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_failure.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:http/http.dart' as http;

export 'coaching_connection.dart';
export 'connection_failure.dart';

class ConnectionRepository implements LogbookConnectionRepository {
  ConnectionRepository({AuthGateway? authGateway, String? projectId})
    // ignore: prefer_initializing_formals
    : _authGateway = authGateway,
      // ignore: prefer_initializing_formals
      _projectId = projectId;

  final AuthGateway? _authGateway;
  final String? _projectId;

  Stream<List<CoachingConnection>> watch(String uid) => FirebaseFirestore
      .instance
      .collection('CoachingConnections')
      .where('participantUids', arrayContains: uid)
      .snapshots()
      .map(
        (snapshot) =>
            [
              for (final doc in snapshot.docs)
                CoachingConnection(
                  doc.id,
                  doc.data(),
                  updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate(),
                ),
            ]..sort(
              (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(
                a.updatedAt ?? DateTime(0),
              ),
            ),
      );

  @override
  Stream<List<BaseListItem>> watchJournal(String uid) => FirebaseFirestore
      .instance
      .collection('SharedRidingEntries')
      .where('riderUid', isEqualTo: uid)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            BaseListItemFirestoreMapper.fromMap(
              Map<String, dynamic>.from(doc.data()['note'] as Map),
            ),
        ],
      );

  @override
  Future<List<BaseListItem>> history(Map<String, Object?> data) async {
    final result = await submit(data);
    return [
      for (final raw in result['entries'] as List)
        _historyNote(Map<String, dynamic>.from(raw as Map)),
    ];
  }

  BaseListItem _historyNote(Map<String, dynamic> raw) {
    final date = raw['date'];
    final parsed = date is String ? DateTime.tryParse(date)?.toLocal() : null;
    return BaseListItem.fromMap({
      ...raw,
      'date': parsed,
      'extra': raw['riderName'],
      'isSelected': raw['editable'] == true,
    });
  }

  @override
  Future<Map<String, dynamic>> submit(Map<String, Object?> data) async {
    final token = _authGateway != null
        ? await _authGateway.getAccessToken()
        : await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ConnectionFailure('Sign in to continue.');
    final project = _projectId ?? FirebaseAuth.instance.app.options.projectId;
    final endpoint = FirebaseEmulators.enabled
        ? FirebaseEmulators.coachingEndpoint()
        : Uri.https(
            'us-central1-$project.cloudfunctions.net',
            '/coachingConnection',
          );
    final http.Response response;
    try {
      response = await http
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'data': data}),
          )
          .timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw const ConnectionFailure(
        'Could not reach the coaching service for this Firebase project.',
      );
    } on TimeoutException {
      throw const ConnectionFailure(
        'The coaching service timed out. Try again.',
      );
    }
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw ConnectionFailure(
        response.statusCode == 404
            ? 'The coaching service is unavailable in this Firebase project.'
            : 'The coaching service returned an unexpected response.',
      );
    }
    if (body is Map) {
      final result = body['result'];
      if (result is Map<String, dynamic>) return result;
      final error = body['error'];
      if (error is Map && error['message'] is String) {
        throw ConnectionFailure(error['message'] as String);
      }
    }
    throw const ConnectionFailure('The request could not be saved. Try again.');
  }
}

class ConnectionsState {
  const ConnectionsState({
    this.email,
    this.connections = const [],
    this.loading = false,
    this.error = false,
    this.actionInProgress = false,
    this.actionFeedback,
  });

  final String? email;
  final List<CoachingConnection> connections;
  final bool loading;
  final bool error;

  /// Whether a submit action (send/accept/decline/cancel/revoke/record/delete)
  /// is currently in progress.
  final bool actionInProgress;

  /// A one-line feedback message describing the last action result.
  /// This is intended for inline UI (Semantics live region) and lightweight
  /// confirmation text.
  final String? actionFeedback;

  CoachingConnection? instructorFor(String studentEmail) => connections
      .where(
        (link) =>
            link.kind == 'rider' &&
            link.status == 'accepted' &&
            link.coach == email &&
            link.learner == studentEmail.toLowerCase(),
      )
      .firstOrNull;

  ConnectionsState copyWith({
    String? email,
    List<CoachingConnection>? connections,
    bool? loading,
    bool? error,
    bool? actionInProgress,
    String? actionFeedback,
    bool clearActionFeedback = false,
  }) {
    return ConnectionsState(
      email: email ?? this.email,
      connections: connections ?? this.connections,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      actionFeedback: clearActionFeedback
          ? null
          : actionFeedback ?? this.actionFeedback,
    );
  }
}

class ConnectionsCubit extends Cubit<ConnectionsState> {
  ConnectionsCubit(this._repository, AppCubit app)
    : _app = app,
      super(const ConnectionsState()) {
    _profile = app.stream.listen(_onProfile);
    _onProfile(app.state);
  }

  final ConnectionRepository _repository;
  final AppCubit _app;
  late final StreamSubscription<AppState> _profile;
  StreamSubscription<List<CoachingConnection>>? _connections;

  String? _uid;

  void _onProfile(AppState profile) {
    final email = profile.isGuest
        ? null
        : profile.usersProfile?.email.toLowerCase();
    final uid = email == null || profile.user.id.isEmpty
        ? null
        : profile.user.id;
    if (email == state.email && uid == _uid) return;
    _uid = uid;
    _listen(email);
  }

  void retry() => _listen(state.email);

  void _listen(String? email) {
    unawaited(_connections?.cancel());
    final uid = _uid;
    emit(ConnectionsState(email: email, loading: uid != null));
    if (uid == null) return;
    _connections = _repository
        .watch(uid)
        .listen(
          (connections) => emit(
            state.copyWith(
              email: email,
              connections: connections,
              loading: false,
              error: false,
            ),
          ),
          onError: (Object _) =>
              emit(state.copyWith(email: email, loading: false, error: true)),
        );
  }

  Future<Map<String, dynamic>?> submit(Map<String, Object?> data) async {
    if (state.actionInProgress) return null;
    emit(state.copyWith(actionInProgress: true, clearActionFeedback: true));
    try {
      final result = await _repository.submit(data);
      if (isClosed) return null;
      final feedback = switch (data['action']) {
        'send' when result['incoming'] == true =>
          'Review the existing incoming request.',
        'send' when result['status'] == 'accepted' =>
          'This connection is already active.',
        'send' => 'Request sent.',
        'accept' when data['transfer'] == true => 'Ownership transferred.',
        _ => 'Connection updated.',
      };
      emit(state.copyWith(actionInProgress: false, actionFeedback: feedback));
      return result;
    } on ConnectionFailure catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            actionInProgress: false,
            actionFeedback: error.message,
          ),
        );
      }
      return null;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            actionInProgress: false,
            actionFeedback: 'The request could not be saved. Try again.',
          ),
        );
      }
      return null;
    }
  }

  Future<void> request({
    String? learner,
    required String coach,
    String? horseId,
  }) async {
    await submit({
      'action': 'send',
      'kind': horseId == null ? 'rider' : 'horse',
      'learnerEmail': learner,
      'coachEmail': coach,
      if (horseId != null) 'horseId': horseId,
    });
  }

  Future<void> change(CoachingConnection link, String action) async {
    await submit({
      'action': action,
      'id': link.id,
      'version': link.version,
      if (link.kind == 'transfer') 'transfer': true,
    });
  }

  Future<bool> recordTraining({
    required CoachingConnection link,
    required String recordId,
    required String notes,
    String? skillId,
    String level = 'LEARNING',
  }) async {
    final result = await submit({
      'action': 'record',
      'recordId': recordId,
      'id': link.id,
      'version': link.version,
      'notes': notes,
      if (skillId != null) 'skillId': skillId,
      if (skillId != null) 'level': level,
    });
    return result != null;
  }

  Future<List<BaseListItem>> historyFor(CoachingConnection link) {
    return _repository.history(
      link.kind == 'rider'
          ? {'action': 'studentHistory', 'id': link.id, 'version': link.version}
          : {
              'action': 'horseHistory',
              'horseId': link.horseId,
              'includeTrainingNotes': true,
            },
    );
  }

  Future<bool> deleteLesson({
    required CoachingConnection link,
    required String entryId,
  }) async {
    final result = await submit({
      'action': 'deleteLesson',
      'id': link.id,
      'version': link.version,
      'entryId': entryId,
    });
    return result != null;
  }

  List<Skill> skillsFor(CoachingConnection link) {
    final rider = link.kind == 'rider';
    return _app.state.allSkills
        .whereType<Skill>()
        .where((skill) => skill.rider == rider)
        .toList();
  }

  @override
  Future<void> close() async {
    await _profile.cancel();
    await _connections?.cancel();
    await super.close();
  }
}
