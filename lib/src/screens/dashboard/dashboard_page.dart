import 'dart:async';
import 'dart:core';
import 'package:elite_wallet/entities/preferences_key.dart';
import 'package:elite_wallet/di.dart';
import 'package:elite_wallet/entities/main_actions.dart';
import 'package:elite_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar_wrapper.dart';
import 'package:elite_wallet/src/screens/dashboard/widgets/market_place_page.dart';
import 'package:elite_wallet/utils/version_comparator.dart';
import 'package:elite_wallet/wallet_type_utils.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/src/screens/yat_emoji_id.dart';
import 'package:elite_wallet/src/widgets/alert_with_one_action.dart';
import 'package:elite_wallet/themes/theme_base.dart';
import 'package:elite_wallet/utils/responsive_layout_util.dart';
import 'package:elite_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:elite_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/src/screens/dashboard/widgets/menu_widget.dart';
import 'package:elite_wallet/src/screens/dashboard/widgets/action_button.dart';
import 'package:elite_wallet/src/screens/dashboard/widgets/balance_page.dart';
import 'package:elite_wallet/src/screens/dashboard/widgets/transactions_page.dart';
import 'package:elite_wallet/src/screens/dashboard/widgets/sync_indicator.dart';
import 'package:elite_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:elite_wallet/main.dart';
import 'package:elite_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elite_wallet/src/screens/release_notes/release_notes_screen.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({
    required this.balancePage,
    required this.dashboardViewModel,
    required this.addressListViewModel,
  });

  final BalancePage balancePage;
  final DashboardViewModel dashboardViewModel;
  final WalletAddressListViewModel addressListViewModel;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayoutUtil.instance.isMobile(context)
          ? _DashboardPageView(
              balancePage: balancePage,
              dashboardViewModel: dashboardViewModel,
              addressListViewModel: addressListViewModel,
            )
          : getIt.get<DesktopSidebarWrapper>(),
    );
  }
}

class _DashboardPageView extends BasePage {
  _DashboardPageView({
    required this.balancePage,
    required this.dashboardViewModel,
    required this.addressListViewModel,
  });

  final BalancePage balancePage;

  @override
  Color get backgroundLightColor =>
      currentTheme.type == ThemeType.bright ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor,
          ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget get endDrawer => MenuWidget(dashboardViewModel);

  @override
  Widget middle(BuildContext context) {
    return SyncIndicator(
        dashboardViewModel: dashboardViewModel,
        onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(Routes.connectionSync));
  }

  @override
  Widget trailing(BuildContext context) {
    final menuButton = Image.asset('assets/images/menu.png',
        color: Theme.of(context)
            .accentTextTheme!
            .displayMedium!
            .backgroundColor);

    return Container(
        alignment: Alignment.centerRight,
        width: 40,
        child: TextButton(
            // FIX-ME: Style
            //highlightColor: Colors.transparent,
            //splashColor: Colors.transparent,
            //padding: EdgeInsets.all(0),
            onPressed: () => onOpenEndDrawer(),
            child: Semantics(label: 'Menu', child: menuButton)));
  }

  final DashboardViewModel dashboardViewModel;
  final WalletAddressListViewModel addressListViewModel;
  int get initialPage => dashboardViewModel.shouldShowMarketPlaceInDashboard ? 1 : 0;
  ObservableList<Widget> pages = ObservableList<Widget>();
  bool _isEffectsInstalled = false;
  StreamSubscription<bool>? _onInactiveSub;

  @override
  Widget body(BuildContext context) {
    final controller = PageController(initialPage: initialPage);

    reaction((_) => dashboardViewModel.shouldShowMarketPlaceInDashboard, (bool value) {
      if (!dashboardViewModel.shouldShowMarketPlaceInDashboard) {
        controller.jumpToPage(0);
      }
      pages.clear();
      _isEffectsInstalled = false;
      _setEffects(context);

      if (value) {
        controller.jumpToPage(1);
      } else {
        controller.jumpToPage(0);
      }
    });
    _setEffects(context);

    return SafeArea(
        minimum: EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
                child: Observer(builder: (context) {
              return PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  itemBuilder: (context, index) => pages[index]);
            })),
            Padding(
                padding: EdgeInsets.only(bottom: 24, top: 10),
                child: Observer(builder: (context) {
                  return ExcludeSemantics(
                    child: SmoothPageIndicator(
                      controller: controller,
                      count: pages.length,
                      effect: ColorTransitionEffect(
                          spacing: 6.0,
                          radius: 6.0,
                          dotWidth: 6.0,
                          dotHeight: 6.0,
                          dotColor: Theme.of(context).indicatorColor,
                          activeDotColor: Theme.of(context)
                              .accentTextTheme!
                              .headlineMedium!
                              .backgroundColor!),
                    ),
                  );
                }
                )),
            Observer(builder: (_) {
              return ClipRect(
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: currentTheme.type == ThemeType.bright
                            ? Color.fromRGBO(255, 255, 255, 0.2)
                            : Colors.transparent,
                        width: 1,
                      ),
                      color: Theme.of(context)
                          .textTheme!
                          .titleLarge!
                          .backgroundColor!,
                    ),
                    child: Container(
                      padding: EdgeInsets.only(
                        left: dashboardViewModel.hasExchangeAction ? 32 : 64,
                        right: dashboardViewModel.hasExchangeAction ? 32 : 64),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: MainActions.all
                            .where((element) => element.canShow?.call(dashboardViewModel) ?? true)
                            .map((action) => Semantics(
                                  button: true,
                                  enabled: (action.isEnabled
                                          ?.call(dashboardViewModel) ??
                                      true),
                                  child: ActionButton(
                                    image: Image.asset(action.image,
                                        height: 24,
                                        width: 24,
                                        color: action.isEnabled?.call(
                                                    dashboardViewModel) ??
                                                true
                                            ? Theme.of(context)
                                                .accentTextTheme!
                                                .displayMedium!
                                                .backgroundColor!
                                            : Theme.of(context)
                                                .accentTextTheme!
                                                .displaySmall!
                                                .backgroundColor!),
                                    title: action.name(context),
                                    onClick: () async => await action.onTap(
                                        context, dashboardViewModel),
                                    textColor: action.isEnabled
                                                ?.call(dashboardViewModel) ??
                                            true
                                        ? null
                                        : Theme.of(context)
                                            .accentTextTheme!
                                            .displaySmall!
                                            .backgroundColor!,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ));
  }

  void _setEffects(BuildContext context) async {
    if (_isEffectsInstalled) {
      return;
    }
    if (dashboardViewModel.shouldShowMarketPlaceInDashboard) {
      pages.add(Semantics(
          label: 'Marketplace Page',
          child: MarketPlacePage(dashboardViewModel: dashboardViewModel)));
    }
    pages.add(Semantics(label: 'Balance Page', child: balancePage));
    pages.add(Semantics(
        label: 'Transactions Page',
        child: TransactionsPage(dashboardViewModel: dashboardViewModel)));
    _isEffectsInstalled = true;

    autorun((_) async {
      if (!dashboardViewModel.isOutdatedElectrumWallet) {
        return;
      }

      if (dashboardViewModel.nextDisplayTime.isAfter(DateTime.now())) {
        return;
      }
      dashboardViewModel.nextDisplayTime =
        DateTime.now().add(Duration(hours: 5));

      await Future<void>.delayed(Duration(seconds: 1));
      if (context.mounted) {
        await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.of(context).pre_seed_title,
                alertContent: S.of(context).outdated_electrum_wallet_description,
                buttonText: S.of(context).understand,
                buttonAction: () => Navigator.of(context).pop());
          });
      }
    });

    final sharedPrefs = await SharedPreferences.getInstance();
    final currentAppVersion =
        VersionComparator.getExtendedVersionNumber(dashboardViewModel.settingsStore.appVersion);
    final lastSeenAppVersion = sharedPrefs.getInt(PreferencesKey.lastSeenAppVersion);
    final isNewInstall = sharedPrefs.getBool(PreferencesKey.isNewInstall);

    if (currentAppVersion != lastSeenAppVersion && !isNewInstall!) {
      await Future<void>.delayed(Duration(seconds: 1));
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return ReleaseNotesScreen(
                title: 'Version ${dashboardViewModel.settingsStore.appVersion}');
          });
      sharedPrefs.setInt(PreferencesKey.lastSeenAppVersion, currentAppVersion);
    } else if (isNewInstall!) {
      sharedPrefs.setInt(PreferencesKey.lastSeenAppVersion, currentAppVersion);
    }

    var needToPresentYat = false;
    var isInactive = false;

    _onInactiveSub = rootKey.currentState!.isInactive.listen((inactive) {
      isInactive = inactive;

      if (needToPresentYat) {
        Future<void>.delayed(Duration(milliseconds: 500)).then((_) {
          showPopUp<void>(
              context: navigatorKey.currentContext!,
              builder: (_) => YatEmojiId(dashboardViewModel.yatStore.emoji));
          needToPresentYat = false;
        });
      }
    });

    dashboardViewModel.yatStore.emojiIncommingStream.listen((String emoji) {
      if (!_isEffectsInstalled || emoji.isEmpty) {
        return;
      }

      needToPresentYat = true;
    });
  }
}
