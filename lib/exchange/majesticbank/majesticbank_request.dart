import 'package:flutter/foundation.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:elite_wallet/exchange/trade_request.dart';

class MajesticBankRequest extends TradeRequest {
  MajesticBankRequest(
      {@required this.from,
      @required this.to,
      @required this.address,
      @required this.fromAmount,
      @required this.toAmount,
      @required this.refundAddress,
      @required this.isReverse});

  CryptoCurrency from;
  CryptoCurrency to;
  String address;
  String fromAmount;
  String toAmount;
  String refundAddress;
  bool isReverse;
}
