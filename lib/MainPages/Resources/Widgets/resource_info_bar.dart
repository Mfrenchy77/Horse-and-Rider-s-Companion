import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';

class ResourceInfoBar extends StatelessWidget {
  const ResourceInfoBar({super.key, required this.resource});
  final Resource resource;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Column(
          children: [
            ///   Info
            Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  flex: 4,
                  child: Text(
                    textAlign: TextAlign.center,
                    '${resource.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Visibility(
                  visible: cubit.canEditResource(resource),
                  child: PopupMenuButton<String>(
                    itemBuilder: (BuildContext menuContext) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (String value) {
                      switch (value) {
                        case 'Edit':
                          state.usersProfile != null
                              ? showDialog<CreateResourcDialog>(
                                  context: context,
                                  builder: (context) => CreateResourcDialog(
                                    skills: state.allSkills,
                                    userProfile: state.usersProfile!,
                                    resource: resource,
                                  ),
                                )
                              : cubit.createError(
                                  'You Are Not Authorized To'
                                  ' Edit Until Logged In',
                                );

                          break;
                        case 'Delete':
                          cubit.deleteResource(
                            resource,
                          );
                          break;
                      }
                    },
                  ),
                ),
              ],
            ),
            gap(),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),

                      ///   Description
                      child: ConstrainedBox(
                        
                        constraints: BoxConstraints.loose(
                          const Size.fromHeight(300),
                        ),
                        child: Text(
                          maxLines: 7,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          resource.description ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                  ///   Image
                  InkWell(
                    key: const Key('ResourceImage'),
                    onTap: () => cubit.openResource(url: resource.url),
                    child: Tooltip(
                      message: 'Go to: ${resource.url}',
                      child: MaxWidthBox(
                        maxWidth: 200,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/horse_logo_and_text_dark.png',
                            image: resource.thumbnail ?? '',
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 500),
                            imageErrorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                'Error loading NetworkImage: $error',
                              );
                              return Image.asset(
                                'assets/horse_logo_and_text_dark.png',
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
