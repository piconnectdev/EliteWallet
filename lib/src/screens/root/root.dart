import 'dart:async';
import 'package:elite_wallet/core/auth_service.dart';
import 'package:elite_wallet/core/totp_request_details.dart';
import 'package:elite_wallet/utils/device_info.dart';
import 'package:elite_wallet/utils/payment_request.dart';
import 'package:flutter/material.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/src/screens/auth/auth_page.dart';
import 'package:elite_wallet/store/app_store.dart';
import 'package:elite_wallet/store/authentication_store.dart';
import 'package:elite_wallet/entities/qr_scanner.dart';
import 'package:uni_links/uni_links.dart';

import '../setup_2fa/setup_2fa_enter_code_page.dart';

class Root extends StatefulWidget {
  Root({
    required Key key,
    required this.authenticationStore,
    required this.appStore,
    required this.child,
    required this.navigatorKey,
    required this.authService,
  }) : super(key: key);

  final AuthenticationStore authenticationStore;
  final AppStore appStore;
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthService authService;
  final Widget child;

  @override
  RootState createState() => RootState();
}

class RootState extends State<Root> with WidgetsBindingObserver {
  RootState()
      : _isInactiveController = StreamController<bool>.broadcast(),
        _isInactive = false,
        _requestAuth = true,
        _postFrameCallback = false;

  Stream<bool> get isInactive => _isInactiveController.stream;
  StreamController<bool> _isInactiveController;
  bool _isInactive;
  bool _postFrameCallback;
  bool _requestAuth;

  StreamSubscription<Uri?>? stream;
  Uri? launchUri;

  @override
  void initState() {
    _requestAuth = widget.authService.requireAuth();
    _isInactiveController = StreamController<bool>.broadcast();
    _isInactive = false;
    _postFrameCallback = false;
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    if (DeviceInfo.instance.isMobile) {
      initUniLinks();
    }
  }

  @override
  void dispose() {
    stream?.cancel();
    super.dispose();
  }

  /// handle app links while the app is already started
  /// whether its in the foreground or in the background.
  Future<void> initUniLinks() async {
    try {
      stream = uriLinkStream.listen((Uri? uri) {
        handleDeepLinking(uri);
      });

      handleDeepLinking(await getInitialUri());
    } catch (e) {
      print(e);
    }
  }

  void handleDeepLinking(Uri? uri) {
    if (uri == null || !mounted) return;

    launchUri = uri;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (isQrScannerShown) {
          return;
        }

        if (!_isInactive && widget.authenticationStore.state == AuthenticationState.allowed) {
          setState(() => _setInactive(true));
        }

        break;
      case AppLifecycleState.resumed:
        setState(() {
          _requestAuth = widget.authService.requireAuth();
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInactive && !_postFrameCallback && _requestAuth) {
      _postFrameCallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.pushNamed(
          Routes.unlock,
          arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
            if (!isAuthenticatedSuccessfully) {
              return;
            } else {
              final useTotp = widget.appStore.settingsStore.useTOTP2FA;
              if (useTotp) {
                _reset();
                auth.close(
                  route: Routes.totpAuthCodePage,
                  arguments: TotpAuthArgumentsModel(
                    onTotpAuthenticationFinished:
                        (bool isAuthenticatedSuccessfully, TotpAuthCodePageState totpAuth) {
                      if (!isAuthenticatedSuccessfully) {
                        return;
                      }
                      _reset();
                      totpAuth.close(
                        route: launchUri != null ? Routes.send : null,
                        arguments: PaymentRequest.fromUri(launchUri),
                      );
                      launchUri = null;
                    },
                    isForSetup: false,
                    isClosable: false,
                  ),
                );
              } else {
                _reset();
                auth.close(
                  route: launchUri != null ? Routes.send : null,
                  arguments: PaymentRequest.fromUri(launchUri),
                );
              launchUri = null;
              }
            }

             
            },
          );
    
       
      });
    } else if (launchUri != null) {
      widget.navigatorKey.currentState?.pushNamed(
        Routes.send,
        arguments: PaymentRequest.fromUri(launchUri),
      );
      launchUri = null;
    }

    return WillPopScope(onWillPop: () async => false, child: widget.child);
  }

  void _reset() {
    setState(() {
      _postFrameCallback = false;
      _setInactive(false);
    });
  }

  void _setInactive(bool value) {
    _isInactive = value;
    _isInactiveController.add(value);
  }
}
