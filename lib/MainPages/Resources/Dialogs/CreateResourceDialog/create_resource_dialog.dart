import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:image_network/image_network.dart';

class CreateResourcDialog extends StatelessWidget {
  const CreateResourcDialog({
    super.key,
    required this.skills,
    required this.resource,
    required this.userProfile,
  });

  final Resource? resource;
  final List<Skill?>? skills;
  final RiderProfile userProfile;

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: resource?.name ?? '');
    final descriptionController =
        TextEditingController(text: resource?.description ?? '');
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
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
            final cubit = context.read<CreateResourceDialogCubit>();
            if (state.urlFetchedStatus == UrlFetchedStatus.fetched) {
              titleController.text = state.title.value;
              descriptionController.text = state.description.value;
            }
            // show a dialog instructing user to enter the title and description
            //in manually
            if (state.urlFetchedStatus == UrlFetchedStatus.error) {
              showDialog<AlertDialog>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error Fetching Website Information'),
                  content: const Text(
                    'Please enter the title and description manually\n\nTo get '
                    'an image, you can right click on the image and select '
                    '"Copy Image Address" and paste it in the image field.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        cubit.clearMetaDataError();
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
            if (state.status.isSubmissionSuccess) {
              Navigator.of(context).pop();
            }
            if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 5),
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
              return

                  //resource != null                  ?

                  Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(
                    resource != null ? 'Edit Resource' : 'Create New Resource',
                  ),
                ),
                body: AlertDialog(
                  scrollable: true,
                  title: Text(
                    resource != null
                        ? 'Edit Resource Resource'
                        : 'Create New Resource',
                  ),
                  content: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Form(
                      child: Column(
                        children: [
                          ///   Resource Url
                          _urlField(context: context, resource: resource),
                          smallGap(),
                          Visibility(
                            visible: state.urlFetchedStatus ==
                                UrlFetchedStatus.initial,
                            child: ElevatedButton(
                              onPressed: () => context
                                  .read<CreateResourceDialogCubit>()
                                  .fetchUrl(),
                              child: const Text('Retrieve Website Information'),
                            ),
                          ),
                          Visibility(
                            visible: state.urlFetchedStatus ==
                                UrlFetchedStatus.fetching,
                            child:
                                const Text('Fetching Website Information...'),
                          ),
                          Column(
                            children: [
                              _image(
                                context: context,
                                resource: resource,
                                state: state,
                              ),
                            ],
                          ),
                          _imageField(
                            context: context,
                            resource: resource,
                            state: state,
                          ),
                          _titleField(
                            titleController: titleController,
                            state: state,
                            context: context,
                            resource: resource,
                          ),
                          gap(),
                          _descriptionField(
                            state: state,
                            context: context,
                            resource: resource,
                            descriptionController: descriptionController,
                          ),

                          ///   Skills picked from filter chips
                          if (state.skills != null)
                            Column(
                              children: [
                                const Text(
                                  'Choose the skills for this Resource',
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: state.skills!.map(
                                    (Skill? skill) {
                                      return FilterChip(
                                        label: Text(skill!.skillName),
                                        selected: state.resourceSkills?.any(
                                              (skillObject) =>
                                                  skillObject?.id == skill.id,
                                            ) ??
                                            false,
                                        onSelected: (value) => context
                                            .read<CreateResourceDialogCubit>()
                                            .resourceSkillsChanged(
                                              skill.id,
                                            ),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ],
                            )
                          else
                            const Text('No Skills Found'),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (state.status.isSubmissionInProgress)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<CreateResourceDialogCubit>()
                              .editResource();
                          Navigator.pop(context);
                        },
                        child: const Text('Submit'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Field that user's can input the image url manually
Widget _imageField({
  required BuildContext context,
  required Resource? resource,
  required CreateResourceDialogState state,
}) {
  return TextFormField(
    initialValue: state.urlFetchedStatus == UrlFetchedStatus.fetched
        ? state.imageUrl
        : resource?.thumbnail ?? '',
    onChanged: (url) =>
        context.read<CreateResourceDialogCubit>().imageUrlChanged(url),
    keyboardType: TextInputType.url,
    decoration: const InputDecoration(
      labelText: 'Image',
      hintText: 'Enter a Web Address',
      icon: Icon(Icons.arrow_circle_down),
    ),
  );
}

Widget _image({
  required BuildContext context,
  Resource? resource,
  required CreateResourceDialogState state,
}) {
  return SizedBox(
    height: 200,
    width: 200,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ImageNetwork(
        onError: const Image(image: AssetImage('assets/horse_icon.png')),
        debugPrint: true,
        image: resource?.thumbnail ?? state.imageUrl,
        height: 200,
        width: 200,
      ),
    ),
  );
}

Widget _urlField({required BuildContext context, required Resource? resource}) {
  return TextFormField(
    initialValue: resource?.url ?? '',
    onChanged: (url) =>
        context.read<CreateResourceDialogCubit>().urlChanged(url),
    keyboardType: TextInputType.url,
    decoration: const InputDecoration(
      labelText: 'Url',
      hintText: 'Enter a Web Address',
      icon: Icon(Icons.arrow_circle_down),
    ),
  );
}

Widget _titleField({
  required TextEditingController titleController,
  required BuildContext context,
  required Resource? resource,
  required CreateResourceDialogState state,
}) {
  return TextFormField(
    controller: titleController,
    minLines: 2,
    maxLines: 10,
    // initialValue: state.urlFetchedStatus == UrlFetchedStatus.fetched
    //     ? state.title.value
    //     : resource?.name ?? '',
    onChanged: (title) =>
        context.read<CreateResourceDialogCubit>().titleChanged(title),
    keyboardType: TextInputType.name,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(
      labelText: 'Title',
      hintText: 'Resource Title',
      icon: Icon(Icons.arrow_circle_down),
    ),
  );
}

Widget _descriptionField({
  required TextEditingController descriptionController,
  required BuildContext context,
  required Resource? resource,
  required CreateResourceDialogState state,
}) {
  return TextFormField(
    controller: descriptionController,
    minLines: 3,
    maxLines: 10,
    // initialValue: state.urlFetchedStatus == UrlFetchedStatus.fetched
    //     ? state.description.value
    //     : resource?.description ?? '',
    onChanged: (description) => context
        .read<CreateResourceDialogCubit>()
        .descriptionChanged(description),
    keyboardType: TextInputType.name,
    textCapitalization: TextCapitalization.sentences,
    decoration: const InputDecoration(
      labelText: 'Description',
      hintText: 'Resource Description',
      icon: Icon(Icons.arrow_circle_down),
    ),
  );
}
