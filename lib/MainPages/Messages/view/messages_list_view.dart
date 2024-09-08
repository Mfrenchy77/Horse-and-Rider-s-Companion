import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/messages_list.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/message_view.dart';

class MessagesView extends StatelessWidget {
  const MessagesView({super.key, required this.isConversations});
  final bool isConversations;
  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      internalAnimations: false,
      body: SlotLayout(
        // Large screen layout
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.large: SlotLayout.from(
            key: const Key('primary'),
            builder: (context) => const MessagesList(
              key: Key('MessagesList'),
            ),
          ),
          // Medium screen layout
          Breakpoints.medium: SlotLayout.from(
            key: const Key('primary'),
            builder: (context) => isConversations
                ? const MessagesList(
                    key: Key('MessagesList'),
                  )
                : const MessageView(
                    key: Key('MessageView'),
                  ),
          ),
//Medium Large Screen Layout
          Breakpoints.mediumLarge: SlotLayout.from(
            key: const Key('primary'),
            builder: (context) => isConversations
                ? const MessagesList(
                    key: Key('MessagesList'),
                  )
                : const MessageView(
                    key: Key('MessageView'),
                  ),
          ),

          // Small screen layout
          Breakpoints.small: SlotLayout.from(
            key: const Key('primary'),
            builder: (context) => isConversations
                ? const MessagesList(
                    key: Key('MessagesList'),
                  )
                : const MessageView(
                    key: Key('MessageView'),
                  ),
          ),
        },
      ),
      secondaryBody: SlotLayout(
        // Large screen layout
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.large: SlotLayout.from(
            key: const Key('secondary'),
            builder: (context) => const MessageView(
              key: Key('MessageView'),
            ),
          ),
        },
      ),
    );
  }
}
