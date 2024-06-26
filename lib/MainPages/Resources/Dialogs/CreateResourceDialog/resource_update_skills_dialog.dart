// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

class UpdateResourceSkills extends StatelessWidget {
  const UpdateResourceSkills({
    super.key,
    required this.resource,
  });
  final Resource? resource;
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
          skills: context.read<AppCubit>().state.allSkills,
          resource: resource,
          isEdit: resource != null,
          usersProfile: context.read<AppCubit>().state.usersProfile,
          keysRepository: context.read<KeysRepository>(),
          resourcesRepository: context.read<ResourcesRepository>(),
        ),
        child:
            BlocListener<CreateResourceDialogCubit, CreateResourceDialogState>(
          listener: (context, state) {
            if (state.status == FormStatus.success) {
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
              final appCubit = context.read<AppCubit>();
              final cubit = context.read<CreateResourceDialogCubit>();
              final canViewSkillEditor = !appCubit.state.isGuest &&
                  (state.usersProfile?.editor ?? false);
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
                        children: cubit
                                .getSkillsForResource(
                                  ids: resource?.skillTreeIds,
                                )
                                ?.map(
                                  (e) => TextButton(
                                    onPressed: () {
                                      appCubit..changeIndex(1)
                                      ..navigateToSkillLevel(skill: e);
                                      context.goNamed(SkillTreePage.name);

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
                        visible: canViewSkillEditor,
                        child: Column(
                          children: [
                            const Divider(),
                            gap(),
                            const Text(
                              'Add or Remove Skills from this Resource',
                            ),
                            smallGap(),
                            SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                children: appCubit.state.allSkills
                                    .map(
                                      (e) => FilterChip(
                                        label: Text(e?.skillName ?? ''),
                                        selected: state.resource?.skillTreeIds
                                                ?.contains(e?.id) ??
                                            false,
                                        onSelected: (value) {
                                          context
                                              .read<CreateResourceDialogCubit>()
                                              .resourceSkillsChanged(
                                                e?.id ?? '',
                                              );
                                        },
                                      ),
                                    )
                                    .toList(),
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
                    visible: !appCubit.state.isGuest,
                    child: TextButton(
                      onPressed: () {
                        context
                            .read<CreateResourceDialogCubit>()
                            .editResource();
                      },
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
