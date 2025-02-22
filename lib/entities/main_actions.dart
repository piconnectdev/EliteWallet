import 'package:elite_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:elite_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:elite_wallet/buy/payfura/payfura_buy_provider.dart';
import 'package:elite_wallet/di.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/src/widgets/alert_with_one_action.dart';
import 'package:elite_wallet/utils/device_info.dart';
import 'package:elite_wallet/utils/show_pop_up.dart';
import 'package:elite_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MainActions {
  final String Function(BuildContext context) name;
  final String image;

  final bool Function(DashboardViewModel viewModel)? isEnabled;
  final bool Function(DashboardViewModel viewModel)? canShow;
  final Future<void> Function(BuildContext context, DashboardViewModel viewModel) onTap;

  MainActions._({
    required this.name,
    required this.image,
    this.isEnabled,
    this.canShow,
    required this.onTap,
  });

  static List<MainActions> all = [
    buyAction,
    receiveAction,
    exchangeAction,
    sendAction,
    sellAction,
  ];

  static MainActions buyAction = MainActions._(
    name: (context) => S.of(context).buy,
    image: 'assets/images/buy.png',
    isEnabled: (viewModel) => viewModel.isEnabledBuyAction,
    canShow: (viewModel) => viewModel.hasBuyAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      final walletType = viewModel.type;

      switch (walletType) {
        case WalletType.bitcoin:
        case WalletType.litecoin:
          if (viewModel.isEnabledBuyAction) {
            if (DeviceInfo.instance.isMobile) {
              Navigator.of(context).pushNamed(Routes.onramperPage);
            } else {
              final uri = getIt.get<OnRamperBuyProvider>().requestUrl();
              await launchUrl(uri);
            }
          }
          break;
        case WalletType.monero:
          if (viewModel.isEnabledBuyAction) {
            if (DeviceInfo.instance.isMobile) {
              Navigator.of(context).pushNamed(Routes.payfuraPage);
            } else {
              final uri = getIt.get<PayfuraBuyProvider>().requestUrl();
              await launchUrl(uri);
            }
          }
          break;
        default:
          await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).buy,
                    alertContent: S.of(context).buy_alert_content,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
      }
    },
  );

  static MainActions receiveAction = MainActions._(
    name: (context) => S.of(context).receive,
    image: 'assets/images/received.png',
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      Navigator.pushNamed(context, Routes.addressPage);
    },
  );

  static MainActions exchangeAction = MainActions._(
    name: (context) => S.of(context).exchange,
    image: 'assets/images/transfer.png',
    isEnabled: (viewModel) => viewModel.isEnabledExchangeAction,
    canShow: (viewModel) => viewModel.hasExchangeAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      if (viewModel.isEnabledExchangeAction) {
        await Navigator.of(context).pushNamed(Routes.exchange);
      }
    },
  );

  static MainActions sendAction = MainActions._(
    name: (context) => S.of(context).send,
    image: 'assets/images/upload.png',
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      Navigator.pushNamed(context, Routes.send);
    },
  );

  static MainActions sellAction = MainActions._(
    name: (context) => S.of(context).sell,
    image: 'assets/images/sell.png',
    isEnabled: (viewModel) => viewModel.isEnabledSellAction,
    canShow: (viewModel) => viewModel.hasSellAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      final walletType = viewModel.type;

      switch (walletType) {
        case WalletType.bitcoin:
          if (viewModel.isEnabledSellAction) {
            final moonPaySellProvider = MoonPaySellProvider();
            final uri = await moonPaySellProvider.requestUrl(
              currency: viewModel.wallet.currency,
              refundWalletAddress: viewModel.wallet.walletAddresses.address,
            );
            await launchUrl(uri);
          }
          break;
        default:
          await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).sell,
                  alertContent: S.of(context).sell_alert_content,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            },
          );
      }
    },
  );
}
