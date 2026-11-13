import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';

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
      listener: (context, state) {
        if (state.usersProfile != null &&
            state.usersProfile!.email == widget.id) {
          context.pushReplacementNamed(ProfilePage.name);
        }
      },
      builder: (context, state) {
        return state.viewingProfile == null ||
                state.viewingProfile?.email != widget.id
            ? const LoadingPage()
            : RiderProfileView(
                profile: state.viewingProfile!,
                key: const Key('ViewingProfileView'),
              );
      },
    );
  }
}
