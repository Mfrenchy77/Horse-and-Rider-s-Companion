import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as google_mobile_ads;
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class BannerAdView extends StatelessWidget {
  const BannerAdView({super.key});

  @override
  Widget build(BuildContext context) {
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
