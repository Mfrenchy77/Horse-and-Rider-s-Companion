import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
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
    return GradientCard(
      margin: EdgeInsets.zero,
      color: Color.alphaBlend(
        colors.primary.withValues(alpha: .12),
        colors.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Text(
              'For sale',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              price.isEmpty ? 'Contact for price' : price,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    listing.location,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Text(
              listing.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
                height: 1.45,
              ),
            ),
          ],
        ),
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
    // In the Ocean/Coral dark theme we draw the gradient *as the dialog surface*.
    // Wrapping an AlertDialog in a surface can look like a full-screen panel on
    // web, since AlertDialog may expand vertically more than expected.
    // Using a Dialog shell keeps the "floating dialog" affordance.
    if (isOceanCoralDarkTheme(context)) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: Colors.transparent,
        child: OceanCoralSurface(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.listing == null
                        ? 'List for sale'
                        : 'Edit sale listing',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These details will be public on the horse profile.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _price,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Asking price (optional)',
                      hintText: 'Include the currency',
                      helperText: 'Leave blank to show Contact for price.',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Default look for non-Ocean/Coral themes.
    return AlertDialog(
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
