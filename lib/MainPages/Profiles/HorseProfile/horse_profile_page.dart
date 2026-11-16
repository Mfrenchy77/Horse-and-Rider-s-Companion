import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class HorseProfilePage extends StatefulWidget {
  const HorseProfilePage({super.key, required this.horseId});

  static const pathParams = 'horseId';
  static const name = 'HorseProfilePage';
  static const path = 'Horse_Profile/:horseId';

  final String horseId;

  @override
  State<HorseProfilePage> createState() => _HorseProfilePageState();
}

class _HorseProfilePageState extends State<HorseProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<AppCubit>().getHorseProfile(id: widget.horseId);
  }

  @override
  void didUpdateWidget(covariant HorseProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horseId != widget.horseId) {
      context.read<AppCubit>().getHorseProfile(id: widget.horseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.horseProfile != current.horseProfile ||
          previous.pageStatus != current.pageStatus,
      builder: (context, state) {
        if (state.horseProfile != null &&
            state.horseProfile?.id == widget.horseId) {
          return HorseProfileView(
            horseProfile: state.horseProfile!,
            key: const Key('horseProfileView'),
          );
        }
        if (state.pageStatus == AppPageStatus.error) {
          return Scaffold(
            appBar: ThemedAppBar(title: const Text('Horse profile')),
            body: AppScaffoldBackdrop(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppSurfaceCard(
                      key: const Key('horsePrivateNotice'),
                      padding: const EdgeInsets.all(AppTokens.spaceMd),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          const AppSectionHeader(
                            title: 'Private Horse Profile',
                          ),
                          Text(
                            'This horse profile is private or unavailable.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTokens.secondaryTextColor(context),
                                ),
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
