// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/Resources/View/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';

class UpdateResourceSkills extends StatelessWidget {
  const UpdateResourceSkills({
    super.key,
    required this.homeState,
    required this.skills,
    required this.resource,
    required this.homeCubit,
    required this.userProfile,
  });
  final HomeState homeState;
  final HomeCubit homeCubit;
  final Resource? resource;
  final List<Skill?>? skills;
  final RiderProfile? userProfile;
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ResourcesRepository>(
          create: (context) => ResourcesRepository(),
        ),
        RepositoryProvider(
          create: (context) => KeysRepository(),
        ),
      ],
      child: BlocProvider(
        create: (context) => CreateResourceDialogCubit(
          skills: skills,
          resource: resource,
          isEdit: resource != null,
          usersProfile: userProfile,
          keysRepository: context.read<KeysRepository>(),
          resourcesRepository: context.read<ResourcesRepository>(),
        ),
        child:
            BlocListener<CreateResourceDialogCubit, CreateResourceDialogState>(
          listener: (context, state) {
            if (state.status.isSubmissionSuccess) {
              Navigator.of(context).pop();
            }
            if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.error),
                  ),
                ).closed.then((_) {
                  context.read<CreateResourceDialogCubit>().clearError();
                });
            }
          },
          child:
              BlocBuilder<CreateResourceDialogCubit, CreateResourceDialogState>(
            builder: (context, state) {
              return AlertDialog(
                title: const Text('Associated Skills for:'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.resource?.name ?? ''),
                      gap(),
                      Wrap(
                        alignment: WrapAlignment.center,
                        runSpacing: 4,
                        children: state.resourceSkills
                                ?.map(
                                  (e) => TextButton(
                                    onPressed: () {
                                      homeCubit.navigateToSkillLevel(
                                        skill: e,
                                        isSplitScreen:
                                            MediaQuery.of(context).size.width >
                                                800,
                                      );
                                      debugPrint('Skill: ${e?.skillName}');
                                      Navigator.pop(context);
                                    },
                                    child: Text(e?.skillName ?? ''),
                                  ),
                                )
                                .toList() ??
                            [const Text('No Skills Found')],
                      ),
                      gap(),
                      Visibility(
                        visible: !homeState.isGuest,
                        child: Column(
                          children: [
                            const Divider(),
                            gap(),
                            const Text(
                                'Add or Remove Skills from this Resource'),
                            smallGap(),
                            SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                children: homeCubit.state.allSkills
                                        ?.map(
                                          (e) => FilterChip(
                                            label: Text(e?.skillName ?? ''),
                                            selected: state
                                                    .resource?.skillTreeIds
                                                    ?.contains(e?.id) ??
                                                false,
                                            onSelected: (value) {
                                              context
                                                  .read<
                                                      CreateResourceDialogCubit>()
                                                  .resourceSkillsChanged(
                                                    e?.id ?? '',
                                                  );
                                            },
                                          ),
                                        )
                                        .toList() ??
                                    [const Text('No Skills Found')],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                  Visibility(
                    visible: !homeState.isGuest,
                    child: TextButton(
                      onPressed: state.status.isValidated
                          ? () {
                              context
                                  .read<CreateResourceDialogCubit>()
                                  .editResource();
                            }
                          : null,
                      child: const Text('Update'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
