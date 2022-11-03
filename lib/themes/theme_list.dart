import 'package:elite_wallet/themes/bright_theme.dart';
import 'package:elite_wallet/themes/dark_theme.dart';
import 'package:elite_wallet/themes/light_theme.dart';
import 'package:elite_wallet/themes/theme_base.dart';

class ThemeList {
  static final all = [brightTheme, lightTheme, darkTheme];

  static final lightTheme = LightTheme(raw: 0);
  static final brightTheme = BrightTheme(raw: 1);
  static final darkTheme = DarkTheme(raw: 2);

  static ThemeBase deserialize({int raw}) {
    switch (raw) {
      case 0:
        return lightTheme;
      case 1:
        return brightTheme;
      case 2:
        return darkTheme;
      default:
        return null;
    }
  }
}