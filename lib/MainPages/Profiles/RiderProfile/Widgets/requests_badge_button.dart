import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/accept_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/deny_request_button.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

class RequestsBadgeButton extends StatelessWidget {
  const RequestsBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.connectionRequests != current.connectionRequests ||
          previous.conversations != current.conversations ||
          previous.usersProfile != current.usersProfile,
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final count = cubit.pendingRequestCount();
        if (count == 0) return const SizedBox.shrink();
        return KeyedSubtree(
          key: const Key('RequestsBadgeButton'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Requests',
                key: const Key('RequestsIconButton'),
                icon: const Icon(Icons.notifications),
                onPressed: () => showRequestsSheet(context),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens the bottom sheet showing pending incoming and outgoing requests.
  static void showRequestsSheet(BuildContext context) {
    final cubit = context.read<AppCubit>();
    showAppGlassModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return BlocProvider<AppCubit>.value(
          value: cubit,
          child: BlocConsumer<AppCubit, AppState>(
            listenWhen: (prev, curr) => prev.acceptStatus != curr.acceptStatus,
            listener: (context, state) {
              if (state.acceptStatus == AcceptStatus.submitted ||
                  state.acceptStatus == AcceptStatus.accepted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage.isEmpty
                            ? 'Request processed'
                            : state.errorMessage,
                      ),
                    ),
                  );
                Navigator.of(context).maybePop();
              }
            },
            builder: (context, state) {
              final appCubit = context.read<AppCubit>();
              final useConnectionRequests = state.connectionRequests != null;
              final requestsList = appCubit.pendingConnectionRequests();
              final outgoingList = appCubit.outgoingConnectionRequests();
              final legacyList = useConnectionRequests
                  ? null
                  : appCubit.pendingRequestConversations();
              final isLoading =
                  state.conversationsState == ConversationsState.loading &&
                  state.connectionRequests == null &&
                  legacyList == null;
              final hasError =
                  state.conversationsState == ConversationsState.error;

              final rows = <Widget>[
                if (isLoading) const LinearProgressIndicator(),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        const Text('Requests could not be loaded.'),
                        TextButton(
                          onPressed: appCubit.retryRequests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                if (!useConnectionRequests && legacyList != null)
                  for (var index = 0; index < legacyList.length; index++)
                    _legacyTile(
                      legacyList[index],
                      state.usersProfile?.name,
                      index,
                    )
                else ...[
                  for (final req in requestsList)
                    _incomingRequestTile(req, state.usersProfile?.name),
                  if (outgoingList.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Sent requests',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    for (final req in outgoingList)
                      _outgoingRequestTile(
                        context,
                        req,
                        state.usersProfile?.name,
                        appCubit,
                      ),
                  ],
                ],
                if (!isLoading &&
                    !hasError &&
                    requestsList.isEmpty &&
                    outgoingList.isEmpty &&
                    (legacyList?.isEmpty ?? true))
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No pending requests.'),
                  ),
              ];

              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text('Requests'),
                      subtitle: Text(
                        'Review and respond to pending connection and '
                        'transfer requests.',
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: rows,
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Updated ${calculateTimeDifferenceBetween(
                              referenceDate: DateTime.now(),
                            )}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Widget _legacyTile(
    Conversation c,
    String? ownName,
    int index,
  ) {
    final otherNames = List<String>.from(c.parties)..remove(ownName);
    final m = c.recentMessage;
    return ListTile(
      title: Text(otherNames.join(', ')),
      subtitle: Text(
        m?.message ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: m == null
          ? null
          : AcceptRequestButton(
              key: Key('Accept_${m.messageId ?? m.id ?? index}'),
              message: m,
            ),
    );
  }

  static Widget _incomingRequestTile(
    ConnectionRequest req,
    String? ownName,
  ) {
    final otherNames = List<String>.from(req.parties)..remove(ownName);
    final title = otherNames.isNotEmpty
        ? otherNames.join(', ')
        : req.senderName;
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (req.summary.isNotEmpty)
            Text(
              req.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              AcceptRequestButton(
                key: Key('Accept_${req.messageId}'),
                request: req,
              ),
              DenyRequestButton(request: req),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _outgoingRequestTile(
    BuildContext context,
    ConnectionRequest req,
    String? ownName,
    AppCubit cubit,
  ) {
    final otherNames = List<String>.from(req.parties)..remove(ownName);
    final targetName = otherNames.isNotEmpty
        ? otherNames.join(', ')
        : (req.recipientName.isNotEmpty ? req.recipientName : req.title);
    return ListTile(
      title: Text(targetName),
      subtitle: Text(
        req.summary.isNotEmpty
            ? '${req.summary}\nAwaiting response'
            : 'Awaiting response',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: TextButton(
        onPressed: cubit.state.acceptStatus == AcceptStatus.loading
            ? null
            : () => cubit.denyConnectionRequest(req),
        child: const Text('Cancel'),
      ),
    );
  }
}
