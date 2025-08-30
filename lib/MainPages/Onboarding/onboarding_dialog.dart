import 'package:flutter/material.dart';

/// Simple onboarding dialog with two tabs: Guest and Signed-in user.
/// Signed-in tab includes a small "Complete Profile" flow.
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({
    super.key,
    this.initialTabIndex = 0,
    this.onProfileComplete,
    this.onSkip,
  });

  final int initialTabIndex;

  /// Called when the profile form is saved.
  ///  Receives a map with keys 'name' and 'email'.
  final void Function(Map<String, String>)? onProfileComplete;
  
  /// Called when the user dismisses/skips onboarding via the close button.
  final VoidCallback? onSkip;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCompleteProfile() async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => const _CompleteProfileDialog(),
    );

    if (result != null && widget.onProfileComplete != null) {
      widget.onProfileComplete!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('onboarding_dialog'),
      title: const Text('Welcome to Horse & Rider Companion'),
      content: SizedBox(
        width: 400,
        height: 320,
        child: Column(
          children: [
            TabBar(
              key: const Key('onboarding_tab_bar'),
              controller: _tabController,
              tabs: const [Tab(text: 'Guest'), Tab(text: 'Signed In')],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const _OnboardingPage(
                    key: Key('onboarding_guest_page'),
                    title: 'Explore as Guest',
                    description: 'Browse horses, riders and public training '
                        'content. Sign in to save preferences and sync data.',
                    assetName: 'assets/horse_logo_and_text_light.png',
                  ),
                  _OnboardingPage(
                    key: const Key('onboarding_signedin_page'),
                    title: 'Get the most out of the app',
                    description:
                        'Create sessions, save horses and manage students. '
                        'Finish your profile to receive personalized session '
                        'suggestions and tailored resources.',
                    assetName: 'assets/horse_logo_and_text_dark.png',
                    action: ElevatedButton(
                      key: const Key('onboarding_complete_profile_button'),
                      onPressed: _showCompleteProfile,
                      child: const Text('Complete Profile'),
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
          key: const Key('onboarding_close_button'),
          onPressed: () {
            // Allow the host to clear the onboarding flag when closing.
            widget.onSkip?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.assetName,
    this.action,
  });

  final String title;
  final String description;
  final String assetName;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(description),
                      const Spacer(),
                      if (action != null) action!,
                    ],
                  ),
                ),
              ),
              // graphic
              SizedBox(
                width: 140,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    assetName,
                    key: Key('onboarding_graphic_${assetName.split('/').last}'),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.image),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompleteProfileDialog extends StatefulWidget {
  const _CompleteProfileDialog();

  @override
  State<_CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends State<_CompleteProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop({
        'name': _nameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('complete_profile_dialog'),
      title: const Text('Complete Your Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('complete_profile_name'),
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            TextFormField(
              key: const Key('complete_profile_email'),
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter email' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('complete_profile_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('complete_profile_save'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
