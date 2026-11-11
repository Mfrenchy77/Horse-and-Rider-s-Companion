import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Initialization/firebase_emulators.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_failure.dart';
import 'package:http/http.dart' as http;

export 'connection_failure.dart';

class CoachingConnection {
  CoachingConnection(this.id, Map<String, dynamic> data)
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
      updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

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
  final DateTime? updatedAt;

  String otherName(String viewer) => viewer == coach ? learnerName : coachName;
  String get requesterName => sender == coach ? coachName : learnerName;
}

class ConnectionRepository {
  Stream<List<CoachingConnection>> watch(String uid) => FirebaseFirestore
      .instance
      .collection('CoachingConnections')
      .where('participantUids', arrayContains: uid)
      .snapshots()
      .map(
        (snapshot) =>
            [
              for (final doc in snapshot.docs)
                CoachingConnection(doc.id, doc.data()),
            ]..sort(
              (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(
                a.updatedAt ?? DateTime(0),
              ),
            ),
      );

  Stream<List<BaseListItem>> watchJournal(String uid) => FirebaseFirestore
      .instance
      .collection('SharedRidingEntries')
      .where('riderUid', isEqualTo: uid)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            BaseListItem.fromJson(
              Map<String, dynamic>.from(doc.data()['note'] as Map),
            ),
        ],
      );

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
    return BaseListItem.fromJson({
      ...raw,
      'date': parsed == null ? null : Timestamp.fromDate(parsed),
      'extra': raw['riderName'],
      'isSelected': raw['editable'] == true,
    });
  }

  Future<Map<String, dynamic>> submit(Map<String, Object?> data) async {
    final auth = FirebaseAuth.instance;
    final token = await auth.currentUser?.getIdToken();
    if (token == null) throw const ConnectionFailure('Sign in to continue.');
    final project = auth.app.options.projectId;
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
  });

  final String? email;
  final List<CoachingConnection> connections;
  final bool loading;
  final bool error;
}

class ConnectionsCubit extends Cubit<ConnectionsState> {
  ConnectionsCubit(this._repository, AppCubit app)
    : super(const ConnectionsState()) {
    _profile = app.stream.listen(_onProfile);
    _onProfile(app.state);
  }

  final ConnectionRepository _repository;
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
          (connections) =>
              emit(ConnectionsState(email: email, connections: connections)),
          onError: (Object _) =>
              emit(ConnectionsState(email: email, error: true)),
        );
  }

  @override
  Future<void> close() async {
    await _profile.cancel();
    await _connections?.cancel();
    await super.close();
  }
}
