import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:intl/intl.dart';

class HorseSalePanel extends StatelessWidget {
  const HorseSalePanel({super.key, required this.horse});

  final HorseProfile horse;

  @override
  Widget build(BuildContext context) {
    final listing = horse.isArchived ? null : horse.saleListing;
    if (listing == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rawPrice = listing.price.trim();
    final amount = RegExp(r'^\d{1,15}$').hasMatch(rawPrice)
        ? int.tryParse(rawPrice)
        : null;
    final price = amount == null
        ? rawPrice
        : NumberFormat.decimalPattern(
            Localizations.localeOf(context).toString(),
          ).format(amount);
    final accent = AppTokens.accentColor(context);
    return AppSurfaceCard(
      borderColor: theme.brightness == Brightness.dark
          ? AppTokens.coralAccent.withValues(alpha: 0.45)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          const AppStatusBadge(
            label: 'For sale',
            icon: Icons.sell_outlined,
            tone: AppStatusTone.coral,
          ),
          Text(
            price.isEmpty ? 'Contact for price' : price,
            style: AppTokens.sectionTitleStyle(context).copyWith(fontSize: 28),
          ),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  listing.location,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTokens.primaryTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          Divider(
            height: 1,
            color: theme.brightness == Brightness.dark
                ? AppTokens.cardBorderDark
                : colors.outlineVariant,
          ),
          Text(
            listing.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTokens.secondaryTextColor(context),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class HorseSaleListingDialog extends StatefulWidget {
  const HorseSaleListingDialog({
    super.key,
    required this.listing,
    this.profileLocation,
  });

  final HorseSaleListing? listing;
  final String? profileLocation;

  @override
  State<HorseSaleListingDialog> createState() => _SaleListingDialogState();
}

class _SaleListingDialogState extends State<HorseSaleListingDialog> {
  final _form = GlobalKey<FormState>();
  late final _price = TextEditingController(text: widget.listing?.price);
  late final _location = TextEditingController(
    text: widget.listing?.location ?? widget.profileLocation?.trim(),
  );
  late final _description = TextEditingController(
    text: widget.listing?.description,
  );

  @override
  void dispose() {
    _price.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OceanCoralAppDialog(
      scrollable: true,
      title: Text(
        widget.listing == null ? 'List for sale' : 'Edit sale listing',
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Text('These details will be public on the horse profile.'),
              TextFormField(
                controller: _price,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Asking price (optional)',
                  hintText: 'Include the currency',
                  helperText: 'Leave blank to show Contact for price.',
                ),
              ),
              TextFormField(
                controller: _location,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'General location',
                  hintText: 'City or region',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Enter a location.'
                    : null,
              ),
              TextFormField(
                controller: _description,
                maxLength: 2500,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Sale description',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Enter a description.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, (
              price: _price.text.trim(),
              location: _location.text.trim(),
              description: _description.text.trim(),
            ));
          },
          child: const Text('Save listing'),
        ),
      ],
    );
  }
}
