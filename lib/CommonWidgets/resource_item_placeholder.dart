import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shimmer/shimmer.dart';

/// Item placeholder for resources, with a shimmer effect.
class ResourceItemPlaceholder extends StatelessWidget {
  const ResourceItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;
    return MaxWidthBox(
      maxWidth: 600,
      child: Card(
        child: Column(
          children: [
            //Simulate rating bar
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey,
                  ),
                  height: 25,
                  width: double.infinity,
                ),
              ),
            ),
            //Divider
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Divider(
                color: isDark ? Colors.white : Colors.black,
                endIndent: 5,
                indent: 5,
              ),
            ),
            // Simulated resource title
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey,
                  ),
                  height: 50,
                  width: double.infinity,
                ),
              ),
            ),

            // Simulated description and image
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder for description
                Flexible(
                  fit: FlexFit.tight,
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey,
                        ),
                        height: 220,
                      ),
                    ),
                  ),
                ),

                // Placeholder for the image
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                      height: 150,
                      width: 200,
                    ),
                  ),
                ),
              ],
            ),
            //divider
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Divider(
                color: isDark ? Colors.white : Colors.black,
                endIndent: 5,
                indent: 5,
              ),
            ),
            // Simulated rating buttons
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey,
                  ),
                  height: 30,
                  width: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
