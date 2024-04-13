import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  static const String name = 'Privacy Policy';
  static const String path = 'PrivacyPolicy';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    return Dialog(
      elevation: 8,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close),
            ),
            const MaxWidthBox(
              maxWidth: 500,
              child: Logo(
                screenName: '',
              ),
            ),
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "This privacy policy applies to Horse & Rider's Companion "
              "(hereby referred to as 'Application') for mobile devices"
              ' that was created by FrenchFriedTechnology (hereby referred'
              " to as 'Service Provider') as an Open Source service. "
              "This service is intended for use 'AS IS'.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Information Collection and Use',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'The Application collects information when you download and'
              ' use it. This information may include information such as:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "• Your device's Internet Protocol address (e.g. IP address)",
            ),
            const Text('• The pages of the Application that you visit, the time'
                ' and date of your visit, the time spent on those pages'),
            const Text('• The time spent on the Application'),
            const Text(
              '• The operating system you use on your mobile device',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => cubit.openResource(
                url: 'https://www.google.com/policies/privacy/',
              ),
              child: const Text('Google Play Services Privacy Policy'),
            ),
            TextButton(
              onPressed: () => cubit.openResource(
                url: 'https://support.google.com/admob/answer/6128543?hl=en',
              ),
              child: const Text('AdMob Privacy Policy'),
            ),
            TextButton(
              onPressed: () => cubit.openResource(
                url: 'https://firebase.google.com/support/privacy',
              ),
              child: const Text('Google Analytics for Firebase Privacy Policy'),
            ),
            TextButton(
              onPressed: () => cubit.openResource(
                url: 'https://firebase.google.com/support/privacy/',
              ),
              child: const Text('Firebase Crashlytics Privacy Policy'),
            ),
            const Text(
              'Third Party Access',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Only aggregated, anonymized data is periodically'
              ' transmitted to external services to aid the Service Provider'
              ' in improving the Application and their service. The Service'
              ' Provider may share your information with third parties in the'
              ' ways that are described in this privacy statement.',
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              'Data Retention Policy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'The Service Provider will retain User Provided data for as'
              ' long as you use the Application and for a reasonable time'
              ' thereafter.',
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              'Children',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'The Service Provider does not use the Application to knowingly'
              ' solicit data from or market to children under the age of 13.',
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              'Security',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'The Service Provider is concerned about safeguarding the'
              ' confidentiality of your information. The Service Provider'
              ' provides physical, electronic, and procedural safeguards'
              ' to protect information they process and maintain.',
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              'Changes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'This Privacy Policy may be updated from time to time for any'
              ' reason. The Service Provider will notify you of any changes'
              ' to the Privacy Policy by updating this page with the new'
              ' Privacy Policy. You are advised to consult this Privacy Policy'
              ' regularly for any changes, as continued use is deemed approval'
              ' of all changes.',
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              'Your Consent',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'By using the Application, you are consenting to the processing'
              ' of your information as set forth in this Privacy Policy now'
              ' and as amended by us.',
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'If you have any questions regarding privacy while using the'
              ' Application, or have questions about the practices, please'
              ' contact the Service Provider via email at'
              ' HorseandRidersCompanion@gmail.com.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
