import 'dart:async';

import 'package:database_repository/src/connection_request.dart';
import 'package:database_repository/src/connection_request_store.dart';
import 'package:database_repository/src/firestore_connection_request_store.dart';

/// Dual-read / synchronized [ConnectionRequestStore] for the migration
/// compatibility window between dedicated `Requests` (`primary`) and legacy
/// `Conversations`/`Messages` (`legacy`).
///
/// - Reads merge pending items from both stores, deduplicating by request
///   identity and suppressing legacy items that are already resolved or
///   superseded in `primary`.
/// - Writes target `primary` (and optionally `legacy` when
///   [mirrorWritesToLegacy] is enabled) while dismissals update both stores so
///   older clients do not continue showing resolved requests as pending.
class CompositeConnectionRequestStore implements ConnectionRequestStore {
  /// Creates a [CompositeConnectionRequestStore].
  CompositeConnectionRequestStore({
    required ConnectionRequestStore primary,
    required ConnectionRequestStore legacy,
    this.mirrorWritesToLegacy = false,
    // ignore: prefer_initializing_formals
  }) : _primary = primary,
       // ignore: prefer_initializing_formals
       _legacy = legacy;

  final ConnectionRequestStore _primary;
  final ConnectionRequestStore _legacy;

  /// Whether [sendRequest] should also mirror to legacy storage for old apps.
  final bool mirrorWritesToLegacy;

  final Set<String> _resolvedKeys = <String>{};

  static String _dedupeKey(ConnectionRequest request) {
    if (request.messageId.isNotEmpty) {
      return '${request.kind.name}:${request.senderEmail}:${request.messageId}';
    }
    return '${request.kind.name}:${request.id}';
  }

  @override
  Stream<List<ConnectionRequest>> watchRequests({required String userEmail}) {
    return Stream.multi((controller) {
      var primaryItems = const <ConnectionRequest>[];
      var legacyItems = const <ConnectionRequest>[];
      var primaryResolvedKeys = const <String>{};
      var hasPrimary = false;
      var hasLegacy = false;

      void emitMerged() {
        if (!hasPrimary && !hasLegacy) return;
        final merged = <String, ConnectionRequest>{};
        for (final item in primaryItems) {
          merged[_dedupeKey(item)] = item;
        }
        for (final item in legacyItems) {
          final key = _dedupeKey(item);
          if (_resolvedKeys.contains(key) ||
              primaryResolvedKeys.contains(key) ||
              item.isAccepted) {
            continue;
          }
          merged.putIfAbsent(key, () => item);
        }
        final sorted = merged.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(sorted);
      }

      final subPrimary = _primary
          .watchRequests(userEmail: userEmail)
          .listen(
            (items) {
              hasPrimary = true;
              primaryItems = items;
              emitMerged();
            },
            onError: controller.addError,
          );
      final subLegacy = _legacy
          .watchRequests(userEmail: userEmail)
          .listen(
            (items) {
              hasLegacy = true;
              legacyItems = items;
              emitMerged();
            },
            onError: controller.addError,
          );
      final subResolved = _primary is FirestoreConnectionRequestStore
          ? _primary
                .watchResolvedKeys(userEmail: userEmail)
                .listen((keys) {
                  primaryResolvedKeys = keys;
                  emitMerged();
                }, onError: controller.addError)
          : null;

      controller.onCancel = () async {
        await subPrimary.cancel();
        await subLegacy.cancel();
        await subResolved?.cancel();
      };
    });
  }

  @override
  Future<void> sendRequest(ConnectionRequest request) async {
    _resolvedKeys.remove(_dedupeKey(request));
    await _primary.sendRequest(request);
    if (mirrorWritesToLegacy) {
      await _legacy.sendRequest(request);
    }
  }

  @override
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
    String status = 'dismissed',
  }) async {
    _resolvedKeys.add(_dedupeKey(request));
    var updated = false;
    try {
      await _primary.dismissRequest(
        request: request,
        dismissalNote: dismissalNote,
        status: status,
      );
      updated = true;
    } catch (e) {
      if (!e.toString().contains('not-found')) rethrow;
    }
    try {
      await _legacy.dismissRequest(
        request: request,
        dismissalNote: dismissalNote,
        status: status,
      );
      updated = true;
    } catch (e) {
      if (!updated) rethrow;
    }
  }
}
