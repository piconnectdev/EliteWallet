import 'package:elite_wallet/exchange/exchange_provider_description.dart';
import 'package:elite_wallet/store/dashboard/trades_store.dart';
import 'package:elite_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/src/widgets/primary_button.dart';
import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/exchange/trade.dart';

class ExchangeConfirmPage extends BasePage {
  ExchangeConfirmPage({required this.tradesStore}) : trade = tradesStore.trade!;

  final TradesStore tradesStore;
  final Trade trade;

  @override
  String get title => S.current.copy_id;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: <Widget>[
          Expanded(
              child: Column(
            children: <Widget>[
              Flexible(
                  child: Center(
                child: Text(
                  S.of(context).exchange_result_write_down_trade_id,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .primaryTextTheme!
                          .titleLarge!
                          .color!),
                ),
              )),
              Container(
                height: 178,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    border: Border.all(
                        width: 1,
                        color: Theme.of(context)
                            .accentTextTheme!
                            .bodySmall!
                            .color!),
                    color: Theme.of(context)
                        .accentTextTheme!
                        .titleLarge!
                        .color!),
                child: Column(
                  children: <Widget>[
                    Expanded(
                        child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "${trade.provider.title} ${S.of(context).trade_id}",
                            style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .primaryTextTheme!
                                    .labelSmall!
                                    .color!),
                          ),
                          Text(
                            trade.id,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .primaryTextTheme!
                                    .titleLarge!
                                    .color!),
                          ),
                        ],
                      ),
                    )),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Builder(
                        builder: (context) => PrimaryButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: trade.id));
                              showBar<void>(
                                  context, S.of(context).copied_to_clipboard);
                            },
                            text: S.of(context).copy_id,
                            color: Theme.of(context)
                                .accentTextTheme!
                                .bodySmall!
                                .backgroundColor!,
                            textColor: Theme.of(context)
                                .primaryTextTheme!
                                .titleLarge!
                                .color!),
                      ),
                    )
                  ],
                ),
              ),
              Flexible(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      (trade.provider.image?.isNotEmpty ?? false)
                          ? Image.asset(trade.provider.image, height: 50)
                          : const SizedBox(),
                      if (!trade.provider.horizontalLogo)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(trade.provider.title),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          )),
          PrimaryButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(Routes.exchangeTrade),
              text: S.of(context).saved_the_trade_id,
              color: Theme.of(context)
                  .accentTextTheme!
                  .bodyLarge!
                  .color!,
              textColor: Colors.white)
        ],
      ),
    );
  }
}
