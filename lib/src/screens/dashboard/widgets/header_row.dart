import 'package:elite_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:elite_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/view_model/dashboard/dashboard_view_model.dart';

class HeaderRow extends StatelessWidget {
  HeaderRow({required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final filterIcon = Image.asset('assets/images/filter_icon.png',
        color: Theme.of(context).textTheme!.bodySmall!.decorationColor!);

    return Container(
      height: 52,
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            S.of(context).transactions,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .accentTextTheme!
                    .displayMedium!
                    .backgroundColor!),
          ),
          GestureDetector(
            onTap: () {
              showPopUp<void>(
                context: context,
                builder: (context) =>
                    FilterWidget(dashboardViewModel: dashboardViewModel)
              );
            },
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).textTheme!.labelSmall!.color!),
              child: filterIcon,
            ),
          )
        ],
      ),
    );
  }
}