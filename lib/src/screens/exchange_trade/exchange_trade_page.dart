import 'dart:ui';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/core/execution_state.dart';
import 'package:elite_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:elite_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:elite_wallet/src/widgets/standart_list_row.dart';
import 'package:elite_wallet/utils/show_bar.dart';
import 'package:elite_wallet/utils/show_pop_up.dart';
import 'package:elite_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:elite_wallet/view_model/send/send_view_model_state.dart';
import 'package:elite_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/src/screens/exchange_trade/widgets/timer_widget.dart';
import 'package:elite_wallet/src/widgets/primary_button.dart';
import 'package:elite_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:elite_wallet/src/widgets/alert_with_one_action.dart';

void showInformation(
    ExchangeTradeViewModel exchangeTradeViewModel, BuildContext context) {
  final fetchingLabel = S.current.fetching;
  final trade = exchangeTradeViewModel.trade;
  final walletName = exchangeTradeViewModel.wallet.name;

  final information = exchangeTradeViewModel.isSendable
      ? S.current.exchange_result_confirm(
          trade.amount ?? fetchingLabel, trade.from.toString(), walletName) +
        exchangeTradeViewModel.extraInfo
      : S.current.exchange_result_description(
          trade.amount ?? fetchingLabel, trade.from.toString()) +
        exchangeTradeViewModel.extraInfo;

  showPopUp<void>(
      context: context,
      builder: (_) => InformationPage(information: information));
}

class ExchangeTradePage extends BasePage {
  ExchangeTradePage({@required this.exchangeTradeViewModel});

  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  String get title => S.current.exchange;

  @override
  Widget trailing(BuildContext context) {
    final questionImage = Image.asset('assets/images/question_mark.png',
        color: Theme.of(context).primaryTextTheme.title.color);

    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            padding: EdgeInsets.all(0),
            onPressed: () => showInformation(exchangeTradeViewModel, context),
            child: questionImage),
      ),
    );
  }

  @override
  Widget body(BuildContext context) =>
      ExchangeTradeForm(exchangeTradeViewModel);
}

class ExchangeTradeForm extends StatefulWidget {
  ExchangeTradeForm(this.exchangeTradeViewModel);

  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  ExchangeTradeState createState() => ExchangeTradeState();
}

class ExchangeTradeState extends State<ExchangeTradeForm> {
  final fetchingLabel = S.current.fetching;

  String get title => S.current.exchange;

  bool _effectsInstalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    showInformation(widget.exchangeTradeViewModel, context);
  }

  @override
  void dispose() {
    super.dispose();
    widget.exchangeTradeViewModel.timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_content.png',
        height: 16,
        width: 16,
        color: Theme.of(context).primaryTextTheme.overline.color);

    _setEffects(context);

    return Container(
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(top: 10, bottom: 16),
          content: Observer(builder: (_) {
            final trade = widget.exchangeTradeViewModel.trade;

            return Column(
              children: <Widget>[
                trade.expiredAt != null
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            Text(
                              S.of(context).offer_expires_in,
                              style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .overline
                                      .color),
                            ),
                            TimerWidget(trade.expiredAt,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .color)
                          ])
                    : Offstage(),
                Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Row(children: <Widget>[
                    Spacer(flex: 3),
                    Flexible(
                        flex: 4,
                        child: Center(
                            child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 3,
                                          color: Theme.of(context)
                                              .accentTextTheme
                                              .subtitle
                                              .color
                                      )
                                  ),
                                  child: QrImage(
                                    data: trade.inputAddress ?? fetchingLabel,
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Theme.of(context)
                                        .accentTextTheme
                                        .subtitle
                                        .color,
                                  ),
                                )))),
                    Spacer(flex: 3)
                  ]),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.exchangeTradeViewModel.items.length,
                    separatorBuilder: (context, index) => Container(
                      height: 1,
                      color: Theme.of(context)
                          .accentTextTheme
                          .subtitle
                          .backgroundColor,
                    ),
                    itemBuilder: (context, index) {
                      final item = widget.exchangeTradeViewModel.items[index];
                      final value = item.data ?? fetchingLabel;

                      final content = StandartListRow(
                        title: item.title,
                        value: value,
                        valueFontSize: 14,
                        image: item.isCopied ? copyImage : null,
                      );

                      return item.isCopied
                          ? Builder(
                              builder: (context) => GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                          ClipboardData(text: value));
                                      showBar<void>(context,
                                          S.of(context).copied_to_clipboard);
                                    },
                                    child: content,
                                  ))
                          : content;
                    },
                  ),
                ),
              ],
            );
          }),
          bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
          bottomSection: Observer(builder: (_) {
            final trade = widget.exchangeTradeViewModel.trade;
            final sendingState =
                widget.exchangeTradeViewModel.sendViewModel.state;

            return widget.exchangeTradeViewModel.isSendable &&
                    !(sendingState is TransactionCommitted)
                ? LoadingPrimaryButton(
                    isDisabled: trade.inputAddress == null ||
                        trade.inputAddress.isEmpty,
                    isLoading: sendingState is IsExecutingState,
                    onPressed: () =>
                        widget.exchangeTradeViewModel.confirmSending(),
                    text: S.of(context).confirm,
                    color: Theme.of(context).accentTextTheme.body2.color,
                    textColor: Colors.white)
                : Offstage();
          })),
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => this.widget.exchangeTradeViewModel.sendViewModel.state,
        (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return ConfirmSendingAlert(
                    alertTitle: S.of(context).confirm_sending,
                    amount: S.of(context).send_amount,
                    amountValue: widget.exchangeTradeViewModel.sendViewModel
                        .pendingTransaction.amountFormatted,
                    fee: S.of(context).send_fee,
                    feeValue: widget.exchangeTradeViewModel.sendViewModel
                        .pendingTransaction.feeFormatted,
                    rightButtonText: S.of(context).ok,
                    leftButtonText: S.of(context).cancel,
                    actionRightButton: () async {
                      Navigator.of(context).pop();
                      await widget.exchangeTradeViewModel.sendViewModel
                          .commitTransaction();
                      await showPopUp<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return Observer(builder: (_) {
                              final state = widget
                                  .exchangeTradeViewModel.sendViewModel.state;

                              if (state is TransactionCommitted) {
                                return Stack(
                                  children: <Widget>[
                                    Container(
                                      color: Theme.of(context).backgroundColor,
                                      child: Center(
                                        child: Image.asset(
                                            'assets/images/birthday_cake.png'),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            top: 220, left: 24, right: 24),
                                        child: Text(
                                          S.of(context).send_success(widget
                                              .exchangeTradeViewModel
                                              .wallet
                                              .currency
                                              .toString()),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .primaryTextTheme
                                                .title
                                                .color,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        left: 24,
                                        right: 24,
                                        bottom: 24,
                                        child: PrimaryButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            text: S.of(context).send_got_it,
                                            color: Theme.of(context)
                                                .accentTextTheme
                                                .body2
                                                .color,
                                            textColor: Colors.white))
                                  ],
                                );
                              }

                              return Stack(
                                children: <Widget>[
                                  Container(
                                    color: Theme.of(context).backgroundColor,
                                    child: Center(
                                      child: Image.asset(
                                          'assets/images/birthday_cake.png'),
                                    ),
                                  ),
                                  BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 3.0, sigmaY: 3.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .backgroundColor
                                              .withOpacity(0.25)),
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 220),
                                          child: Text(
                                            S.of(context).send_sending,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .color,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                        left: 24,
                                        right: 24,
                                        bottom: 24,
                                        child: PrimaryButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            text: S.of(context).send_got_it,
                                            color: Theme.of(context)
                                                .accentTextTheme
                                                .body2
                                                .color,
                                            textColor: Colors.white))
                                ],
                              );
                            });
                          });
                    },
                    actionLeftButton: () => Navigator.of(context).pop(),
                    feeFiatAmount: widget.exchangeTradeViewModel.sendViewModel.pendingTransactionFeeFiatAmount
                        +  ' ' + widget.exchangeTradeViewModel.sendViewModel.fiat.title,
                    fiatAmountValue: widget.exchangeTradeViewModel.sendViewModel
                            .pendingTransactionFiatAmount +
                        ' ' +
                        widget.exchangeTradeViewModel.sendViewModel.fiat.title,
                    outputs: widget.exchangeTradeViewModel.sendViewModel
                                 .outputs);
              });
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).sending,
                    alertContent: S.of(context).transaction_sent,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }
    });

    _effectsInstalled = true;
  }
}
