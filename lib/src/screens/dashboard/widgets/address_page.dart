import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/src/widgets/alert_with_one_action.dart';
import 'package:elite_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:elite_wallet/src/widgets/keyboard_done_button.dart';
import 'package:elite_wallet/src/widgets/primary_button.dart';
import 'package:elite_wallet/store/settings_store.dart';
import 'package:elite_wallet/themes/theme_base.dart';
import 'package:elite_wallet/utils/show_pop_up.dart';
import 'package:elite_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:elite_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:elite_wallet/src/screens/receive/widgets/qr_widget.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';

class AddressPage extends BasePage {
  AddressPage({@required this.addressListViewModel,
                this.walletViewModel})
      : _cryptoAmountFocus = FocusNode();

  final WalletAddressListViewModel addressListViewModel;
  final DashboardViewModel walletViewModel;

  final FocusNode _cryptoAmountFocus;

  @override
  String get title => S.current.receive;

  @override
  Color get backgroundLightColor => currentTheme.type == ThemeType.bright
      ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget leading(BuildContext context) {
    final _backButton = Icon(Icons.arrow_back_ios,
      color: Theme.of(context).accentTextTheme.display3.backgroundColor,
      size: 16,);

    return SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            padding: EdgeInsets.all(0),
            onPressed: () => onClose(context),
            child: _backButton),
      ),
    );
  }

  @override
  Widget middle(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
          color: Theme.of(context).accentTextTheme.display3.backgroundColor),
    );
  }

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).accentColor,
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor,
          ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: scaffold);

  @override
  Widget body(BuildContext context) {
    autorun((_) async {
      if (!walletViewModel.isOutdatedElectrumWallet
        || !walletViewModel.settingsStore.shouldShowReceiveWarning) {
        return;
      }

      await Future<void>.delayed(Duration(seconds: 1));
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithTwoActions(
                alertTitle: S.of(context).pre_seed_title,
                alertContent: S.of(context).outdated_electrum_wallet_receive_warning,
                leftButtonText: S.of(context).understand,
                actionLeftButton: () => Navigator.of(context).pop(),
                rightButtonText: S.of(context).do_not_show_me,
                actionRightButton: () {
                  walletViewModel.settingsStore.setShouldShowReceiveWarning(false);
                  Navigator.of(context).pop();
                });
          });
    });

    return KeyboardActions(
        autoScroll: false,
        disableScroll: true,
        tapOutsideToDismiss: true,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor:
                Theme.of(context).accentTextTheme.body2.backgroundColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _cryptoAmountFocus,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              )
            ]),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Observer(builder: (_) => QRWidget(
                      addressListViewModel: addressListViewModel,
                      amountTextFieldFocusNode: _cryptoAmountFocus,
                      isAmountFieldShow: !addressListViewModel.hasAccounts,
                      isLight: walletViewModel.settingsStore.currentTheme.type == ThemeType.light))
              ),
              Observer(builder: (_) {
                return addressListViewModel.hasAddressList
                    ? GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(Routes.receive),
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.only(left: 24, right: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(25)),
                              border: Border.all(
                                  color:
                                      Theme.of(context).textTheme.subhead.color,
                                  width: 1),
                              color: Theme.of(context).buttonColor),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Observer(
                                  builder: (_) => Text(
                                        addressListViewModel.hasAccounts
                                            ? S
                                                .of(context)
                                                .accounts_subaddresses
                                            : S.of(context).addresses,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .accentTextTheme
                                                .display3
                                                .backgroundColor),
                                      )),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .display3
                                    .backgroundColor,
                              )
                            ],
                          ),
                        ),
                      )
                    : Text(
                        S.of(context).electrum_address_disclaimer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context)
                              .accentTextTheme
                              .display2
                              .backgroundColor));
              })
            ],
          ),
        ));
  }
}
