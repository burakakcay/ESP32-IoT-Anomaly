import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';

Future<bool> showSignOutDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.signOutButton),
      content: Text(l10n.signOutConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.signOutButton),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
