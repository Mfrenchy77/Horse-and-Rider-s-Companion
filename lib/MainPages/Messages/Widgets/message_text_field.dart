import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

class MessageTextField extends StatefulWidget {
  const MessageTextField({super.key});

  @override
  State<MessageTextField> createState() => _MessageTextFieldState();
}

class _MessageTextFieldState extends State<MessageTextField> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    // Listen to state changes to clear text field
    context.read<AppCubit>().stream.listen((state) {
      if (state.messageText.isEmpty) {
        _controller.clear();
      }
    });

    final isDark = SharedPrefs().isDarkMode;
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 60,
            width: double.infinity,
            color: isDark ? Colors.grey.shade800 : Colors.white,
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      context.read<AppCubit>().messageTextChanged(value);
                    },
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        color: HorseAndRidersTheme().getTheme().primaryColor,
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            context.read<AppCubit>().sendMessage();
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                        ),
                      ),
                      hintText: 'Write message...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black54,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
