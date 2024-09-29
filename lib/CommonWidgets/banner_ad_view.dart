import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as google_mobile_ads;
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class BannerAdView extends StatelessWidget {
  const BannerAdView({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the platform is web
    if (kIsWeb) {
      // show a box as a placeholder for the web ad
      return Container(
        // this needs to change when the theme is updated
        color: Theme.of(context).appBarTheme.backgroundColor,
        width: double.infinity,
        height: 50,
        child: const Center(
          child: Text(
            'Web Ad Placeholder',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'Roboto',
              fontSize: 15,
              decoration: TextDecoration.none,
              
            ),
          ),
        ),
      );
      // TODO(mfrencny77): Implement Web Ad here when we get them working
      // return WebAdBanner();
    } else {
      return BlocBuilder<AppCubit, AppState>(
        buildWhen: (previous, current) =>
            previous.isBannerAdReady != current.isBannerAdReady ||
            previous.bannerAd != current.bannerAd,
        builder: (context, state) {
          if (state.isBannerAdReady) {
            return Visibility(
              visible: state.isBannerAdReady,
              child: Container(
                color: HorseAndRidersTheme().getTheme().primaryColor,
                width: double.infinity,
                height: state.bannerAd?.size.height.toDouble(),
                alignment: Alignment.center,
                child: google_mobile_ads.AdWidget(ad: state.bannerAd!),
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      );
    }
  }
}
