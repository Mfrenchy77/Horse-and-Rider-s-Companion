import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  static const String routeName = 'About';
  static const String name = 'About';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close),
            ),
            const MaxWidthBox(maxWidth: 600, child: Logo(screenName: '')),
            const Text(
              "Welcome to Horse & Rider's Companion!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our Story',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'My name is Matt French, a horse trainer based in the beautiful'
              ' city of San Diego. With years of experience in the field, I'
              ' have always been passionate about enhancing the skills of'
              ' my clients and the welfare of their horses. Recognizing'
              ' the need for a comprehensive tool that could help track'
              ' progress and consolidate high-quality educational resources,'
              " I created Horse & Rider's Companion.",
            ),
            const SizedBox(height: 16),
            const Text(
              'Our Mission',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "The mission of Horse & Rider's Companion, is to empower"
              ' the equestrian community by providing a robust platform'
              ' where trainers, riders, and horse enthusiasts can track'
              ' training progress, access curated resources, and share'
              ' knowledge. I believe in the strength of the community and'
              ' the value of sharing experiences and insights.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Community-Driven Approach',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "The core of Horse & Rider's Companion is its community-driven"
              ' content. The skills and training paths available on our'
              ' platform are created and refined by the community, for the'
              ' community. This approach ensures that our content is not '
              'only up-to-date and comprehensive but also tailored to the'
              ' real needs and experiences of horse enthusiasts worldwide.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Features',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              '- Skill Tracking: Keep a detailed log of training sessions'
              ' and milestones for both riders and horses, '
              'allowing for a clear view of progress over time.\n'
              '- Curated Educational Resources: Access a library of '
              'high-quality, community-rated resources ranging from beginner '
              'tips to advanced techniques.\n'
              '- Community Contributions: Every member has the opportunity to'
              ' contribute insights, vote on the usefulness of content, '
              'and create paths that benefit others.\n'
              '- Quality Assurance: With community feedback and expert '
              'reviews, the information on our platform maintains high '
              'standards of reliability and relevance.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Join Our Community',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Whether you're a seasoned equestrian or just starting out,"
              " Horse & Rider's Companion is your go-to place for tracking, "
              'learning, and connecting with like-minded individuals. We are '
              'more than just an app, we are a community that grows together.\n'
              "\nWe invite you to use Horse & Rider's Companion today"
              ' and take your first step towards a more informed and '
              'connected equestrian journey, together.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "For any inquiries or feedback, please don't hesitate to reach"
              ' out to us at HorseandRidersCompanion@gmail.com.',
            ),
            smallGap(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FilledButton.tonalIcon(
                  icon: const Icon(
                    Icons.close,
                  ),
                  onPressed: () => context.pop(),
                  label: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
