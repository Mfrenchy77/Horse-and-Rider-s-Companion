import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderWebsiteLink extends StatelessWidget {
  const RiderWebsiteLink({super.key, required this.homeUrl});
  final String? homeUrl;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: homeUrl == null ? null : () => launchUrl(Uri.parse(homeUrl ?? '')),
      child: const Text(
        'Website Link',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
