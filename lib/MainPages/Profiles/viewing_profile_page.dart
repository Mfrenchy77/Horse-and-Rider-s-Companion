import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class ViewingProfilePage extends StatefulWidget {
  const ViewingProfilePage({super.key, required this.id});

  static const pathParams = 'id';
  static const path = 'Viewing/:id';
  static const name = 'ViewingProfilePage';

  final String id;

  @override
  State<ViewingProfilePage> createState() => _ViewingProfilePageState();
}

class _ViewingProfilePageState extends State<ViewingProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ViewingProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    final cubit = context.read<AppCubit>();
    final state = cubit.state;
    if (state.usersProfile != null && state.usersProfile!.email == widget.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacementNamed(ProfilePage.name);
      });
      return;
    }
    if (state.viewingProfile == null ||
        state.viewingProfile?.email != widget.id) {
      cubit.getProfileToBeViewed(email: widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.usersProfile?.email != current.usersProfile?.email,
      buildWhen: (previous, current) =>
          previous.viewingProfile != current.viewingProfile ||
          previous.isError != current.isError ||
          previous.pageStatus != current.pageStatus ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.usersProfile != null &&
            state.usersProfile!.email == widget.id) {
          context.pushReplacementNamed(ProfilePage.name);
        }
      },
      builder: (context, state) {
        if (state.viewingProfile != null &&
            state.viewingProfile?.email == widget.id) {
          return RiderProfileView(
            profile: state.viewingProfile!,
            key: const Key('ViewingProfileView'),
          );
        }
        if (state.isError || state.pageStatus == AppPageStatus.error) {
          final message = state.errorMessage.trim().isNotEmpty
              ? state.errorMessage
              : 'This rider profile is unavailable or could not be loaded.';
          return Scaffold(
            appBar: ThemedAppBar(title: const Text('Rider profile')),
            body: AppScaffoldBackdrop(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                    child: AppSurfaceCard(
                      key: const Key('viewingProfileError'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppTokens.spaceSm,
                        children: [
                          const AppSectionHeader(
                            title: 'Rider Profile Unavailable',
                          ),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTokens.secondaryTextColor(context),
                                ),
                          ),
                          const SizedBox(height: AppTokens.spaceXs),
                          Wrap(
                            spacing: AppTokens.spaceSm,
                            runSpacing: AppTokens.spaceSm,
                            children: [
                              AppOutlinedButton(
                                key: const Key('viewingProfileRetryButton'),
                                icon: Icons.refresh,
                                label: 'Retry',
                                onPressed: () => context
                                    .read<AppCubit>()
                                    .getProfileToBeViewed(email: widget.id),
                              ),
                              AppOutlinedButton(
                                key: const Key('viewingProfileBackButton'),
                                icon: Icons.arrow_back,
                                label: 'Back to Profile',
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.goNamed(ProfilePage.name);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const LoadingPage();
      },
    );
  }
}
