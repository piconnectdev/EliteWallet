import 'package:elite_wallet/ionia/ionia_gift_card.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/typography.dart';
import 'package:flutter/material.dart';

class IoniaMoreOptionsPage extends BasePage {
  IoniaMoreOptionsPage(this.giftCard);

  final IoniaGiftCard giftCard;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.more_options,
      style: textMediumSemiBold(
        color: Theme.of(context)
            .accentTextTheme!
            .displayLarge!
            .backgroundColor!,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 10,
          ),
          Center(
            child: Text(
              S.of(context).choose_from_available_options,
              style: textMedium(
                color: Theme.of(context).primaryTextTheme!.titleLarge!.color!,
              ),
            ),
          ),
          SizedBox(height: 40),
          InkWell(
            onTap: () async {
              final amount = await Navigator.of(context)
                  .pushNamed(Routes.ioniaCustomRedeemPage, arguments: [giftCard]) as String?;
              if (amount != null && amount.isNotEmpty) {
                Navigator.pop(context);
              }
            },
            child: _GradiantContainer(
              content: Padding(
                padding: const EdgeInsets.only(top: 24, left: 20, right: 24, bottom: 50),
                child: Text(
                  S.of(context).custom_redeem_amount,
                  style: textXLargeSemiBold(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _GradiantContainer extends StatelessWidget {
  const _GradiantContainer({Key? key, required this.content}) : super(key: key);

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: content,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
    );
  }
}
