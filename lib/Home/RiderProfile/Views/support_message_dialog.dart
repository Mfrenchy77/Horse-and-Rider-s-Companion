import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';

class SupportMessageDialog extends StatelessWidget {
  const SupportMessageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);
    return BlocProvider(
      create: (context) => HomeCubit(
        viewingProfile: null,
        user: user,
        horseProfileRepository: context.read<HorseProfileRepository>(),
        riderProfileRepository: context.read<RiderProfileRepository>(),
        skillTreeRepository: context.read<SkillTreeRepository>(),
        messagesRepository: context.read<MessagesRepository>(),
        resourcesRepository: context.read<ResourcesRepository>(),
      ),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final homeCubit = context.read<HomeCubit>();
          return Scaffold(
            body: AlertDialog(
              title: const Text('Send Message to Support'),
              content: TextFormField(
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: homeCubit.messageToSupportChanged,
                decoration: const InputDecoration(
                  hintText: 'Enter your message here',
                ),
                maxLines: 5,
              ),
              actions: [
                TextButton(
                  onPressed:Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: homeCubit.sendMessageToSupport,
                  child: const Text('Send'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
