import 'package:cached_network_image/cached_network_image.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Resources/View/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

class CreateResourcDialog extends StatelessWidget {
  const CreateResourcDialog({
    super.key,
    required this.userProfile,
    required this.resource,
  });

  final RiderProfile userProfile;
  final Resource? resource;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ResourcesRepository(),
      child: BlocProvider(
        create: (context) => CreateResourceDialogCubit(
          resourcesRepository: context.read<ResourcesRepository>(),
          usersProfile: userProfile,
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
                          Visibility(
                            visible: state.urlFetchedStatus ==
                                UrlFetchedStatus.fetched,
                            child: Column(
                              children: [
                                _image(
                                  context: context,
                                  resource: resource,
                                  state: state,
                                ),
                                _titleField(
                                  state: state,
                                  context: context,
                                  resource: resource,
                                ),
                                gap(),
                                _descriptionField(
                                  state: state,
                                  context: context,
                                  resource: resource,
                                ),
                              ],
                            ),
                          ),
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
                      TextButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              HorseAndRidersTheme().getTheme().primaryColor,
                        ),
                        onPressed:
                            state.urlFetchedStatus != UrlFetchedStatus.fetched
                                ? null
                                : () {
                                    context
                                        .read<CreateResourceDialogCubit>()
                                        .editResource(resource);
                                    Navigator.pop(context);
                                  },
                        child: const Text('Submit'),
                      ),
                  ],
                ),
              );
              // : Scaffold(
              //     appBar: AppBar(
              //       title: const Text('Create New Resource'),
              //     ),
              //     body: AlertDialog(
              //       // backgroundColor: COLOR_CONST.DEFAULT_5,
              //       scrollable: true,
              //       //titleTextStyle: FONT_CONST.MEDIUM_WHITE,
              //       title: const Text('Create New Resource'),
              //       content: Padding(
              //         padding: const EdgeInsets.all(8),
              //         child: Form(
              //           child: Column(
              //             children: <Widget>[
              //               ///   Resource Url
              //               _urlField(context: context, resource: resource)
              //             ],
              //           ),
              //         ),
              //       ),
              //       actions: [
              //         if (state.status.isSubmissionInProgress)
              //           const CircularProgressIndicator()
              //         else
              //           ElevatedButton(
              //             style: ElevatedButton.styleFrom(
              //               backgroundColor: HorseAndRidersTheme()
              //                   .getTheme()
              //                   .primaryColor,
              //             ),
              //             onPressed: !state.status.isValid
              //                 ? null
              //                 : () {
              //                     context
              //                         .read<CreateResourceDialogCubit>()
              //                         .createResource();
              //                     //Navigator.pop(context);
              //                   },
              //             child: const Text('Submit'),
              //           )
              //       ],
              //     ),
              //   );
            },
          ),
        ),
      ),
    );
  }
}

Widget _image({
  required BuildContext context,
  Resource? resource,
  required CreateResourceDialogState state,
}) {
  final isDark = SharedPrefs().isDarkMode;

  return SizedBox(
    height: 200,
    width: 200,
    child: CachedNetworkImage(
      imageUrl: state.urlFetchedStatus == UrlFetchedStatus.fetched
          ? state.imageUrl
          : resource?.thumbnail ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Image(
        image: AssetImage(
          isDark
              ? 'assets/horse_icon_circle_dark.png'
              : 'assets/horse_icon_circle.png',
        ),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
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
  required BuildContext context,
  required Resource? resource,
  required CreateResourceDialogState state,
}) {
  return TextFormField(
    minLines: 2,
    maxLines: 10,
    initialValue: state.urlFetchedStatus == UrlFetchedStatus.fetched
        ? state.title.value
        : resource?.name ?? '',
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
  required BuildContext context,
  required Resource? resource,
  required CreateResourceDialogState state,
}) {
  return TextFormField(
    minLines: 3,
    maxLines: 10,
    initialValue: state.urlFetchedStatus == UrlFetchedStatus.fetched
        ? state.description.value
        : resource?.description ?? '',
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
