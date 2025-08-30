import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';

class GuestOnboardingDialog extends StatefulWidget {
  const GuestOnboardingDialog({super.key, this.onSkip});

  final VoidCallback? onSkip;

  @override
  State<GuestOnboardingDialog> createState() => _GuestOnboardingDialogState();
}

class _GuestOnboardingDialogState extends State<GuestOnboardingDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _syncAppIndex();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _syncAppIndex() {
    final cubit = context.read<AppCubit>();
    switch (_tabController.index) {
      case 0:
        cubit.changeIndex(0);
        break;
      case 1:
        cubit.changeIndex(1);
        break;
      case 2:
        cubit.changeIndex(2);
        break;
      default:
        break;
    }
  }

  void _createAccount() {
    // Navigate to registration page in Auth and close dialog
    context.goNamed(
      AuthPage.name,
      queryParameters: const {'mode': 'register'},
    );
    widget.onSkip?.call();
    Navigator.of(context).pop();
  }

  void _logIn() {
    // Navigate to login page in Auth and close dialog
    context.goNamed(
      AuthPage.name,
      queryParameters: const {'mode': 'login'},
    );
    widget.onSkip?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('guest_onboarding_dialog'),
      backgroundColor: Colors.blue,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      contentTextStyle: const TextStyle(color: Colors.white),
      title: const Text("Welcome! Explore Horse & Rider's Companion"),
      content: SizedBox(
        width: 440,
        height: 360,
        child: Column(
          children: [
            TabBar(
              key: const Key('guest_onboarding_tab_bar'),
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Skill Tree'),
                Tab(text: 'Resources'),
                Tab(text: 'Why Account?'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _InfoPane(
                    title: 'Profiles',
                    description:
                        'Browse rider and horse profiles to see skills, notes,'
                        ' and progress.',
                    icon: Icons.person_outline,
                  ),
                  _InfoPane(
                    title: 'Skill Tree',
                    description:
                        'Explore our curated skill tree for riders and horses'
                        ' to plan training.',
                    icon: Icons.account_tree_outlined,
                  ),
                  _InfoPane(
                    title: 'Resources',
                    description:
                        'Read community-vetted resources with ratings and'
                        ' comments.',
                    icon: Icons.library_books_outlined,
                  ),
                  _InfoPane(
                    title: 'Create a Free Account',
                    description:
                        'Save your progress, manage horses & students, and'
                        ' sync across devices.',
                    icon: Icons.lock_open,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('guest_onboarding_close'),
          onPressed: () {
            widget.onSkip?.call();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Skip'),
        ),
        TextButton(
          key: const Key('guest_login_button'),
          onPressed: _logIn,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Log In'),
        ),
        ElevatedButton(
          key: const Key('guest_create_account_button'),
          onPressed: _createAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
          ),
          child: const Text('Create Free Account'),
        ),
      ],
    );
  }
}

class _InfoPane extends StatelessWidget {
  const _InfoPane({
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
