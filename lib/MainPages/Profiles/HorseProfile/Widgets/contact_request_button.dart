import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

/// Button that says "Request to be Contact" or "Remove Contact"
/// depending on the if the user is in the viewingProfile's contact list
class ContactRequestButton extends StatelessWidget {
  const ContactRequestButton({super.key, required this.profile});

  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        // Conditions to not show the button at all
        final shouldNotShowButton = state.usersProfile == null ||
            state.viewingProfile == null ||
            state.isGuest ||
            state.usersProfile?.email == profile.email;

        if (shouldNotShowButton) {
          return const SizedBox.shrink();
        }

        // Determine if the profile is already a contact
        final isAlreadyContact = profile.savedProfilesList
                ?.any((element) => element.id == state.usersProfile!.email) ??
            false;

        return Tooltip(
          message:
              isAlreadyContact ? 'Remove from Contacts' : 'Add to Contacts',
          child: OutlinedButton(
            onPressed: () => isAlreadyContact
                ? cubit.removeFromContacts(riderProfile: profile)
                : cubit.addToContact(riderProfile: profile),
            child:
                Text(isAlreadyContact ? 'Remove Contact' : 'Add to Contacts'),
          ),
        );
      },
    );
  }
}
