import 'package:elite_wallet/di.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/src/screens/auth/auth_page.dart';
import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/src/screens/dashboard/desktop_widgets/desktop_dashboard_navbar.dart';
import 'package:elite_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu.dart';
import 'package:elite_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu_item.dart';
import 'package:elite_wallet/src/screens/dashboard/desktop_widgets/desktop_wallet_selection_dropdown.dart';
import 'package:elite_wallet/src/screens/dashboard/widgets/sync_indicator.dart';
import 'package:elite_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:elite_wallet/view_model/dashboard/desktop_sidebar_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:elite_wallet/router.dart' as Router;
import 'package:mobx/mobx.dart';

class DesktopSidebarWrapper extends BasePage {
  final Widget child;
  final DesktopSidebarViewModel desktopSidebarViewModel;
  final DashboardViewModel dashboardViewModel;
  final GlobalKey<NavigatorState> desktopNavigatorKey;

  DesktopSidebarWrapper({
    required this.child,
    required this.desktopSidebarViewModel,
    required this.dashboardViewModel,
    required this.desktopNavigatorKey,
  });

  @override
  ObstructingPreferredSizeWidget appBar(BuildContext context) => DesktopDashboardNavbar(
        leading: Padding(
          padding: EdgeInsets.only(left: sideMenuWidth),
          child: getIt<DesktopWalletSelectionDropDown>(),
        ),
        middle: SyncIndicator(
          dashboardViewModel: dashboardViewModel,
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(Routes.connectionSync),
        ),
        trailing: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              Routes.unlock,
              arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
                if (isAuthenticatedSuccessfully) {
                  auth.close();
                }
              },
            );
          },
          child: Icon(Icons.lock_outline),
        ),
      );

  @override
  bool get resizeToAvoidBottomInset => false;

  final pageController = PageController();

  final selectedIconPath = 'assets/images/desktop_transactions_solid_icon.png';
  final unselectedIconPath = 'assets/images/desktop_transactions_outline_icon.png';

  double get sideMenuWidth => 76.0;

  @override
  Widget body(BuildContext context) {
    _setEffects();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Observer(builder: (_) {
          return SideMenu(
            width: sideMenuWidth,
            topItems: [
              SideMenuItem(
                imagePath: 'assets/images/wallet_outline.png',
                isSelected: desktopSidebarViewModel.currentPage == SidebarItem.dashboard,
                onTap: () => desktopSidebarViewModel.onPageChange(SidebarItem.dashboard),
              ),
              SideMenuItem(
                onTap: () {
                  String? currentPath;

                  desktopNavigatorKey.currentState?.popUntil((route) {
                    currentPath = route.settings.name;
                    return true;
                  });

                  switch (currentPath) {
                    case Routes.transactionsPage:
                      desktopSidebarViewModel.resetSidebar();
                      break;
                    default:
                      desktopSidebarViewModel.resetSidebar();
                      Future.delayed(Duration(milliseconds: 10), () {
                        desktopSidebarViewModel.onPageChange(SidebarItem.transactions);
                        desktopNavigatorKey.currentState?.pushNamed(Routes.transactionsPage);
                      });
                  }
                },
                isSelected: desktopSidebarViewModel.currentPage == SidebarItem.transactions,
                imagePath: desktopSidebarViewModel.currentPage == SidebarItem.transactions
                    ? selectedIconPath
                    : unselectedIconPath,
              ),
            ],
            bottomItems: [
              SideMenuItem(
                  imagePath: 'assets/images/support_icon.png',
                  isSelected: desktopSidebarViewModel.currentPage == SidebarItem.support,
                  onTap: () => desktopSidebarViewModel.onPageChange(SidebarItem.support)),
              SideMenuItem(
                imagePath: 'assets/images/settings_outline.png',
                isSelected: desktopSidebarViewModel.currentPage == SidebarItem.settings,
                onTap: () => desktopSidebarViewModel.onPageChange(SidebarItem.settings),
              ),
            ],
          );
        }),
        Expanded(
          child: PageView(
            controller: pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              child,
              Container(
                color: Theme.of(context).colorScheme.background,
                padding: EdgeInsets.all(20),
                child: Navigator(
                  initialRoute: Routes.support,
                  onGenerateRoute: (settings) => Router.createRoute(settings),
                  onGenerateInitialRoutes: (NavigatorState navigator, String initialRouteName) {
                    return [
                      navigator.widget.onGenerateRoute!(RouteSettings(name: initialRouteName))!
                    ];
                  },
                ),
              ),
              Navigator(
                initialRoute: Routes.desktop_settings_page,
                onGenerateRoute: (settings) => Router.createRoute(settings),
                onGenerateInitialRoutes: (NavigatorState navigator, String initialRouteName) {
                  return [
                    navigator.widget.onGenerateRoute!(RouteSettings(name: initialRouteName))!
                  ];
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setEffects() async {
    reaction<SidebarItem>((_) => desktopSidebarViewModel.currentPage, (page) {
      String? currentPath;

      desktopNavigatorKey.currentState?.popUntil((route) {
        currentPath = route.settings.name;
        return true;
      });
      if (page == SidebarItem.transactions) {
        return;
      }

      if (currentPath == Routes.transactionsPage) {
        Navigator.of(desktopNavigatorKey.currentContext!).pop();
      }
      pageController.jumpToPage(page.index);
    });
  }
}
