import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PendingTransactionWarningDialog extends StatelessWidget {
  const PendingTransactionWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Text(
          Utils.getTranslatedLabel(
              context, pendingPaymentTransactionWarningKey),
          style: TextStyle(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
              fontSize: 16.0,
              fontWeight: FontWeight.w600),
        ),
      ),
      actions: [
        CupertinoButton(
            child: Text(Utils.getTranslatedLabel(context, waitKey)),
            onPressed: () {
              Navigator.of(context).pop(false);
            }),
        CupertinoButton(
            child: Text(Utils.getTranslatedLabel(context, continuePaymentKey)),
            onPressed: () {
              Navigator.of(context).pop(true);
            }),
      ],
    );
  }
}
