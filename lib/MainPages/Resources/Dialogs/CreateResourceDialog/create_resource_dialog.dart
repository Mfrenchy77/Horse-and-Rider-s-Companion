import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/resource_icon.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_select_chip.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_type_icon.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
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
    final imageUrlController =
        TextEditingController(text: resource?.thumbnail ?? '');
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
          // keysRepository: context.read<KeysRepository>(),
          resourcesRepository: context.read<ResourcesRepository>(),
        ),
        child:
            BlocListener<CreateResourceDialogCubit, CreateResourceDialogState>(
          listenWhen: (previous, current) =>
              previous.title != current.title ||
              previous.imageUrl != current.imageUrl||
              previous.description != current.description ||
              previous.submitStatus != current.submitStatus ||
              previous.urlFetchedStatus != current.urlFetchedStatus ,
          listener: (context, state) {
            final cubit = context.read<CreateResourceDialogCubit>();
            if (state.urlFetchedStatus == UrlFetchedStatus.fetched) {
              titleController.text = state.title;
              descriptionController.text = state.description;
              imageUrlController.text = state.imageUrl;
            }
            // show a dialog instructing user to enter the title and description
            //in manually
            // if (state.urlFetchedStatus == UrlFetchedStatus.error) {
            //   showDialog<AlertDialog>(
            //     context: context,
            //     builder: (context) => AlertDialog(
            //       title: const Text('Error Fetching Website Information'),
            //       content: const Text(
            //         'Some websites do not allow their information to be easily'
            //         ' transferred. You can still add this resource manually by'
            //         ' entering the Title, Description, and Image URL yourself.'
            //         ' To get the Image URL, right-click (or long press on'
            //         " mobile) the image, select 'Copy Image Link', and paste it"
            //         ' into the Image URL field.',
            //       ),
            //       actions: [
            //         TextButton(
            //           onPressed: () {
            //             cubit.clearMetaDataError();
            //             Navigator.pop(context);
            //           },
            //           child: const Text('Close'),
            //         ),
            //       ],
            //     ),
            //   );
            //   cubit.clearError();
            // }
            if (state.submitStatus == ResourceSubmitStatus.success) {
              Navigator.of(context).pop();
            }
            if (state.isError ||
                state.submitStatus == ResourceSubmitStatus.error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 5),
                    backgroundColor: Colors.red,
                    content: Text(state.error),
                  ),
                ).closed.then((_) => cubit.clearError());
            }
          },
          child:
              BlocBuilder<CreateResourceDialogCubit, CreateResourceDialogState>(
            builder: (context, state) {
              final cubit = context.read<CreateResourceDialogCubit>();
              return Scaffold(
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
                    child: SingleChildScrollView(
                      child: Form(
                        child: Column(
                          children: [
                            //   Resource Url
                            _urlField(
                              cubit: cubit,
                              state: state,
                              resource: resource,
                            ),
                            smallGap(),

                            if (state.urlFetchedStatus ==
                                UrlFetchedStatus.fetching)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 16),
                                    Text('Fetching website information...'),
                                  ],
                                ),
                              ),
                            if (state.urlFetchedStatus ==
                                UrlFetchedStatus.error)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Failed to fetch website information.'
                                  ' Please enter details manually.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            if (state.urlFetchedStatus ==
                                    UrlFetchedStatus.fetched ||
                                state.urlFetchedStatus ==
                                    UrlFetchedStatus.manual)
                              Column(
                                children: [
                                  ResourcesItem(
                                    isResourceList: false,
                                    resource: Resource(
                                      name: state.title,
                                      description: state.description,
                                      thumbnail: state.imageUrl,
                                      lastEditDate: DateTime.now(),
                                    ),
                                  ),
                                  gap(),
                                  _titleField(
                                    state: state,
                                    context: context,
                                    resource: resource,
                                    titleController: titleController,
                                  ),
                                  gap(),
                                  _descriptionField(
                                    state: state,
                                    context: context,
                                    resource: resource,
                                    descriptionController:
                                        descriptionController,
                                  ),
                                  gap(),
                                  _imageField(
                                    state: state,
                                    context: context,
                                    resource: resource,
                                    imageUrlController: imageUrlController,
                                  ),
                                ],
                              ),

                            ///   Skills picked from Input chips
                            Visibility(
                              visible: state.urlFetchedStatus ==
                                  UrlFetchedStatus.fetched,
                              child: Column(
                                children: [
                                  const Text(
                                    'Choose the skills for this Resource',
                                  ),
                                  smallGap(),
                                  SearchBar(
                                    hintText: 'Search Skills',
                                    onChanged: cubit.searchSkills,
                                  ),
                                  smallGap(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      DropdownButton<CategoryFilter>(
                                        value: state.categoryFilter,
                                        onChanged: cubit.categoryFilterChanged,
                                        items: CategoryFilter.values
                                            .map(
                                              (category) => DropdownMenuItem(
                                                value: category,
                                                child: Text(
                                                  category
                                                      .toString()
                                                      .split('.')
                                                      .last,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      smallGap(),
                                      DropdownButton<DifficultyFilter>(
                                        value: state.difficultyFilter,
                                        onChanged:
                                            cubit.difficultyFilterChanged,
                                        items: DifficultyFilter.values
                                            .map(
                                              (difficulty) => DropdownMenuItem(
                                                value: difficulty,
                                                child: Text(
                                                  difficulty
                                                      .toString()
                                                      .split('.')
                                                      .last,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                  gap(),
                                  Wrap(
                                    spacing: 8,
                                    children: state.filteredSkills!.map(
                                      (Skill? skill) {
                                        return SkillSelectChip(
                                          trailingIcon: SkillTypeIcon(
                                            difficulty: skill?.difficulty,
                                            isRider: skill?.rider ?? true,
                                          ),
                                          skill: skill,
                                          leadingIcon: ResourceIcon(
                                            category: skill?.category,
                                            difficulty: skill?.difficulty,
                                          ),
                                          textLabel: skill?.skillName ?? '',
                                          isSelected: state.resourceSkills?.any(
                                                (skillObject) =>
                                                    skillObject?.id ==
                                                    skill?.id,
                                              ) ??
                                              false,
                                          onTap: (value) => context
                                              .read<CreateResourceDialogCubit>()
                                              .resourceSkillsChanged(
                                                skill?.id ?? '',
                                              ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (state.submitStatus == ResourceSubmitStatus.submitting)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed:
                            !cubit.isFormValid() ? null : cubit.editResource,
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
  required TextEditingController imageUrlController,
}) {
  return TextFormField(
    controller: imageUrlController,
    onFieldSubmitted: (url) =>
        context.read<CreateResourceDialogCubit>().getMetadata(url),
    // onChanged: (url) =>
    //     context.read<CreateResourceDialogCubit>().getMetadata(url),
    keyboardType: TextInputType.url,
    decoration: const InputDecoration(
      labelText: 'Image',
      hintText: 'Enter a Web Address',
      icon: Icon(Icons.arrow_circle_down),
    ),
  );
}

class ResourceImage extends StatelessWidget {
  const ResourceImage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateResourceDialogCubit, CreateResourceDialogState>(
      builder: (context, state) {
        return SizedBox(
          height: 200,
          width: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ImageNetwork(
              onError: const Image(
                image: AssetImage('assets/horse_icon_circle.png'),
              ),
              debugPrint: true,
              image: state.imageUrl,
              height: 200,
              width: 200,
            ),
          ),
        );
      },
    );
  }
}

Widget _urlField({
  required CreateResourceDialogCubit cubit,
  required Resource? resource,
  required CreateResourceDialogState state,
}) {
  return TextFormField(
    validator: (value) {
      if (state.url.isNotValid) {
        return 'Please enter a valid URL';
      } else {
        return null;
      }
    },
    initialValue: resource?.url ?? '',
    onFieldSubmitted: cubit.getMetadata,
    onChanged: cubit.urlChanged,
    keyboardType: TextInputType.url,
    decoration: const InputDecoration(
      // suffixIcon: IconButton(
      //   tooltip: 'Fetch Website Information',
      //   onPressed: state.url.value.isEmpty
      //       ? null
      //       : () => cubit.getMetadata(state.url.value),
      //   icon: const Icon(Icons.send),
      // ),
      labelText: 'Resource URL',
      hintText: 'Enter the resource URL',
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
    minLines: 1,
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
    minLines: 1,
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
