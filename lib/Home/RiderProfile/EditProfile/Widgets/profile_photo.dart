import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        final isDark = SharedPrefs().isDarkMode;
        final cubit = context.read<EditRiderProfileCubit>();
        final isSmallScreen = MediaQuery.of(context).size.width < 600;
        return InkWell(
          onTap: cubit.riderProfilePicClicked,
          child: Column(
            children: [
              ///   Image
              if (state.isSubmitting)
                const CircularProgressIndicator()
              else
                CachedNetworkImage(
                  imageUrl: '${state.picUrl}',
                  placeholder: (context, url) => const Image(
                    image: AssetImage('assets/horse_icon_01.png'),
                  ),
                  errorWidget: (context, url, error) => const Image(
                    image: AssetImage('assets/horse_icon_01.png'),
                  ),
                  height: isSmallScreen ? 85 : 150,
                  width: isSmallScreen ? 85 : 150,
                ),
              smallGap(),
              Text(
                state.riderProfile?.picUrl != null
                    ? 'Tap to Change your Photo'
                    : ' Tap to Add a Photo',
              ),
              smallGap(),
              Divider(
                color: isDark ? Colors.white : Colors.black,
                endIndent: 20,
                indent: 20,
              ),
              smallGap(),
            ],
          ),
        );
      },
    );
  }
}
