import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/accept_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/messages_list_page.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

class RequestsBadgeButton extends StatelessWidget {
  const RequestsBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final count = cubit.pendingRequestCount();
        if (count == 0) return const SizedBox.shrink();
        return Stack(
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        );
      },
    );
  }

  void _showRequestsSheet(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final list = cubit.pendingRequestConversations();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final cubit = context.read<AppCubit>();
        return BlocProvider<AppCubit>.value(
          value: cubit,
          child: BlocListener<AppCubit, AppState>(
            listenWhen: (prev, curr) => prev.acceptStatus != curr.acceptStatus,
            listener: (context, state) {
              if (state.acceptStatus == AcceptStatus.accepted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Request accepted')),
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
                  subtitle: Text('Incoming requests awaiting your action'),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final c = list[index];
                      final otherNames = List<String>.from(c.parties)
                        ..remove(cubit.state.usersProfile?.name);
                      final m = c.recentMessage;
                      return ListTile(
                        onTap: () {
                          // Open the conversation
                          cubit.setConversation(c.id);
                          context.goNamed(
                            MessagePage.name,
                            pathParameters: {MessagePage.pathParams: c.id},
                          );
                        },
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
                                onBeforeAccept: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text('Request accepted'),
                                      ),
                                    );
                                },
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
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            key: const Key('ViewAllRequestsButton'),
                            onPressed: () {
                              Navigator.pop(context);
                              context.pushNamed(MessagesPage.name);
                            },
                            child: const Text('View All'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
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
