import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/accept_request_button.dart';
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
                onPressed: () => _showRequestsSheet(context),
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

  void _showRequestsSheet(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final useConnectionRequests = cubit.state.connectionRequests != null;
    final requestsList = cubit.pendingConnectionRequests();
    final legacyList = useConnectionRequests
        ? null
        : cubit.pendingRequestConversations();
    showAppGlassModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final cubit = context.read<AppCubit>();
        return BlocProvider<AppCubit>.value(
          value: cubit,
          child: BlocListener<AppCubit, AppState>(
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
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Text('Requests'),
                    subtitle: Text(
                      'Review and respond to pending connection and transfer '
                      'requests.',
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: requestsList.length,
                      itemBuilder: (context, index) {
                        if (!useConnectionRequests && legacyList != null) {
                          final c = legacyList[index];
                          final otherNames = List<String>.from(c.parties)
                            ..remove(cubit.state.usersProfile?.name);
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
                                    key: Key(
                                      'Accept_${m.messageId ?? m.id ?? index}',
                                    ),
                                    message: m,
                                  ),
                          );
                        }
                        final req = requestsList[index];
                        final otherNames = List<String>.from(req.parties)
                          ..remove(cubit.state.usersProfile?.name);
                        final title = otherNames.isNotEmpty
                            ? otherNames.join(', ')
                            : req.senderName;
                        return ListTile(
                          title: Text(title),
                          subtitle: Text(
                            req.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: AcceptRequestButton(
                            key: Key('Accept_${req.messageId}'),
                            request: req,
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          // ignore: lines_longer_than_80_chars
                          'Updated ${calculateTimeDifferenceBetween(referenceDate: DateTime.now())}',
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
            ),
          ),
        );
      },
    );
  }
}
