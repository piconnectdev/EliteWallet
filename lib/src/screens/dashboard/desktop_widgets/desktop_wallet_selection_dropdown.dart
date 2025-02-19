import 'package:another_flushbar/flushbar.dart';
import 'package:elite_wallet/core/auth_service.dart';
import 'package:elite_wallet/entities/desktop_dropdown_item.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/src/screens/dashboard/desktop_widgets/dropdown_item_widget.dart';
import 'package:elite_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:elite_wallet/utils/show_bar.dart';
import 'package:elite_wallet/utils/show_pop_up.dart';
import 'package:elite_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:elite_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:elite_wallet/wallet_type_utils.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DesktopWalletSelectionDropDown extends StatefulWidget {
  final WalletListViewModel walletListViewModel;
  final AuthService _authService;

  DesktopWalletSelectionDropDown(this.walletListViewModel, this._authService, {Key? key})
      : super(key: key);

  @override
  State<DesktopWalletSelectionDropDown> createState() => _DesktopWalletSelectionDropDownState();
}

class _DesktopWalletSelectionDropDownState extends State<DesktopWalletSelectionDropDown> {
  final moneroIcon = Image.asset('assets/images/monero_logo.png', height: 24, width: 24);
  final bitcoinIcon = Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
  final litecoinIcon = Image.asset('assets/images/litecoin_icon.png', height: 24, width: 24);
  final havenIcon = Image.asset('assets/images/haven_logo.png', height: 24, width: 24);
  final nonWalletTypeIcon = Image.asset('assets/images/close.png', height: 24, width: 24);

  Image _newWalletImage(BuildContext context) => Image.asset(
        'assets/images/new_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).primaryTextTheme!.titleLarge!.color!,
      );

  Image _restoreWalletImage(BuildContext context) => Image.asset(
        'assets/images/restore_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).primaryTextTheme!.titleLarge!.color!,
      );

  Flushbar<void>? _progressBar;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Observer(builder: (context) {
      final dropDownItems = [
        ...widget.walletListViewModel.wallets
            .map((wallet) => DesktopDropdownItem(
                  isSelected: wallet.isCurrent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: DropDownItemWidget(
                        title: wallet.name,
                        image: wallet.isEnabled ? _imageFor(type: wallet.type) : nonWalletTypeIcon),
                  ),
                  onSelected: () => _onSelectedWallet(wallet),
                ))
            .toList(),
        DesktopDropdownItem(
          onSelected: () => _navigateToCreateWallet(),
          child: DropDownItemWidget(
            title: S.of(context).create_new,
            image: _newWalletImage(context),
          ),
        ),
        DesktopDropdownItem(
          onSelected: () => _navigateToRestoreWallet(),
          child: DropDownItemWidget(
            title: S.of(context).restore_wallet,
            image: _restoreWalletImage(context),
          ),
        ),
      ];

      return DropdownButton<DesktopDropdownItem>(
        items: dropDownItems
            .map(
              (wallet) => DropdownMenuItem<DesktopDropdownItem>(
                child: wallet.child,
                value: wallet,
              ),
            )
            .toList(),
        onChanged: (item) {
          item?.onSelected();
        },
        dropdownColor: themeData.textTheme!.bodyLarge?.decorationColor,
        style: TextStyle(color: themeData.primaryTextTheme!.titleLarge?.color),
        selectedItemBuilder: (context) => dropDownItems.map((item) => item.child).toList(),
        value: dropDownItems.firstWhere((element) => element.isSelected),
        underline: const SizedBox(),
        focusColor: Colors.transparent,
        borderRadius: BorderRadius.circular(15.0),
      );
    });
  }

  void _onSelectedWallet(WalletListItem selectedWallet) async {
    if (selectedWallet.isCurrent || !selectedWallet.isEnabled) {
      return;
    }
    final confirmed = await showPopUp<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertWithTwoActions(
                  alertTitle: S.of(context).change_wallet_alert_title,
                  alertContent: S.of(context).change_wallet_alert_content(selectedWallet.name),
                  leftButtonText: S.of(context).cancel,
                  rightButtonText: S.of(context).change,
                  actionLeftButton: () => Navigator.of(context).pop(false),
                  actionRightButton: () => Navigator.of(context).pop(true));
            }) ??
        false;

    if (confirmed) {
      await _loadWallet(selectedWallet);
    }
  }

  Image _imageFor({required WalletType type}) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.monero:
        return moneroIcon;
      case WalletType.litecoin:
        return litecoinIcon;
      case WalletType.haven:
        return havenIcon;
      default:
        return nonWalletTypeIcon;
    }
  }

  Future<void> _loadWallet(WalletListItem wallet) async {
    widget._authService.authenticateAction(context,
        onAuthSuccess: (isAuthenticatedSuccessfully) async {
      if (!isAuthenticatedSuccessfully) {
        return;
      }

      try {
        changeProcessText(S.of(context).wallet_list_loading_wallet(wallet.name));
        await widget.walletListViewModel.loadWallet(wallet);
        hideProgressText();
        setState(() {});
      } catch (e) {
        changeProcessText(S.of(context).wallet_list_failed_to_load(wallet.name, e.toString()));
      }
    });
  }

  void _navigateToCreateWallet() {
    if (isSingleCoin) {
      Navigator.of(context)
          .pushNamed(Routes.newWallet, arguments: widget.walletListViewModel.currentWalletType);
    } else {
      Navigator.of(context).pushNamed(Routes.newWalletType);
    }
  }

  void _navigateToRestoreWallet() {
    if (isSingleCoin) {
      Navigator.of(context)
          .pushNamed(Routes.restoreWallet, arguments: widget.walletListViewModel.currentWalletType);
    } else {
      Navigator.of(context).pushNamed(Routes.restoreWalletType);
    }
  }

  void changeProcessText(String text) {
    _progressBar = createBar<void>(text, duration: null)..show(context);
  }

  void hideProgressText() {
    _progressBar?.dismiss();
    _progressBar = null;
  }
}
