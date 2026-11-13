import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderWebsiteLink extends StatelessWidget {
  const RiderWebsiteLink({super.key, required this.homeUrl});
  final String? homeUrl;
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: homeUrl != null && homeUrl!.isNotEmpty,
      child: OutlinedButton.icon(
        onPressed: homeUrl == null
            ? null
            : () => launchUrl(Uri.parse(homeUrl!.trim())),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Website'),
      ),
    );
  }
}
