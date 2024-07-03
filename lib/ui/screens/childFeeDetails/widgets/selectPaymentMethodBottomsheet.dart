import 'package:eschool/data/models/paymentGateway.dart';
import 'package:eschool/ui/widgets/bottomsheetTopTitleAndCloseButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class SelectPaymentMethodBottomsheet extends StatelessWidget {
  final List<PaymentGeteway> paymentGeteways;
  const SelectPaymentMethodBottomsheet(
      {super.key, required this.paymentGeteways});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * (0.075),
          vertical: MediaQuery.of(context).size.height * (0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomsheetTopTitleAndCloseButton(
              onTapCloseButton: () {
                Navigator.of(context).pop();
              },
              titleKey: choosePayViaKey,
            ),
            Column(
              children: paymentGeteways.map((paymentGateway) {
                return ListTile(
                  onTap: () {
                    Navigator.of(context).pop(paymentGateway);
                  },
                  tileColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                  dense: false,
                  title: Text(
                    "${Utils.getTranslatedLabel(context, payUsingKey)} ${paymentGateway.paymentMethod}",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
