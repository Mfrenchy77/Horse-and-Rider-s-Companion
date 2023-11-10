import 'package:flutter/material.dart';

class ResponsiveScaler {
  // Method to get the scale factor based on screen width
  double scaleFactor(BuildContext context) {
    // You can set breakpoints according to your needs
    final screenWidth = MediaQuery.of(context).size.width;

    // Base scale factor for standard screen width (e.g., 360.0).
    // Adjust as needed.
    const baseScaleFactor = 1.1;

    // Increment factor for each "step" in width. Adjust as needed.
    const incrementFactor = 0.05; // for every 100px increase, for example

    // Calculate scale factor. The max function ensures the scale factor
    // doesn't go below the baseScaleFactor.
    return baseScaleFactor + ((screenWidth - 360.0) / 100.0) * incrementFactor;
  }

  // Method to get responsive text size
  double responsiveTextSize(BuildContext context, double baseSize) {
    final scale = scaleFactor(context);
    return baseSize * scale; // scale the base size
  }

  // Method to get responsive icon size
  double responsiveIconSize(BuildContext context, double baseSize) {
    final scale = scaleFactor(context);
    return baseSize * scale; // scale the base size
  }

  double caluclateToolBarHeight({required BuildContext context}) {
    // Determine the screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Define your breakpoint for mobile and web
    const mobileBreakpoint = 400.0; // example breakpoint for mobile
    const webBreakpoint = 1200.0; // example breakpoint for web

    // Define AppBar heights for mobile and web
    const appBarHeightMobile = 56.0; // height for mobile
    const appBarHeightWeb = 100.0; // height for web

    // Calculate the scale factor
    var scaleFactor =
        (screenWidth - mobileBreakpoint) / (webBreakpoint - mobileBreakpoint);

    // Make sure scaleFactor is between 0.0 and 1.0
    scaleFactor = scaleFactor.clamp(0.0, 1.0);

    // Calculate the AppBar height based on the screen width
    final appBarHeight = appBarHeightMobile +
        (appBarHeightWeb - appBarHeightMobile) * scaleFactor;
    return appBarHeight;
  }

  double dynamicSpacing({required BuildContext context}) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Define your breakpoints
    const largeScreenWidth = 1200; // example for 'large' screen width
    const smallScreenWidth = 320; // example for 'small' screen width

    // Map screenWidth to a value between 8 and 15
    final value = 8.0 +
        ((screenWidth - smallScreenWidth) *
                (15 - 8) /
                (largeScreenWidth - smallScreenWidth))
            .round();

    // Clamp the value to be between 8 and 15
    return value.clamp(8, 15);
  }
}

// double scaledIconSize(
//   BuildContext context,
//   double minSize,
//   double maxSize,
// ) {
//   final screenWidth = MediaQuery.of(context).size.width;
//   // Assuming 320 is the width of a small screen and 600
//   //is the width of a large screen
//   final double scaleFactor = ((screenWidth - 320) / (600 - 320)).clamp(0, 1);
//   return scaleIconSize(minSize, maxSize, scaleFactor);
// }

// double scaleIconSize(double minSize, double maxSize, double scaleFactor) {
//   if (scaleFactor < 0 || scaleFactor > 1) {
//     throw ArgumentError('Scale factor must be between 0 and 1.');
//   }
//   return minSize + (maxSize - minSize) * scaleFactor;
// }
