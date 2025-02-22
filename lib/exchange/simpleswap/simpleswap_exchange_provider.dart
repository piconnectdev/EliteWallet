import 'dart:convert';
import 'package:elite_wallet/exchange/exchange_pair.dart';
import 'package:elite_wallet/exchange/exchange_provider.dart';
import 'package:elite_wallet/exchange/exchange_provider_description.dart';
import 'package:elite_wallet/exchange/simpleswap/simpleswap_request.dart';
import 'package:elite_wallet/exchange/trade_not_created_exeption.dart';
import 'package:elite_wallet/exchange/trade_not_found_exeption.dart';
import 'package:elite_wallet/exchange/trade_state.dart';
import 'package:elite_wallet/utils/device_info.dart';
import 'package:ew_core/crypto_currency.dart';
import 'package:elite_wallet/exchange/trade_request.dart';
import 'package:elite_wallet/exchange/trade.dart';
import 'package:elite_wallet/exchange/limits.dart';
import 'package:elite_wallet/.secrets.g.dart' as secrets;
import 'package:ew_core/http_port_redirector.dart';
import 'package:elite_wallet/store/settings_store.dart';

class SimpleSwapExchangeProvider extends ExchangeProvider {
  SimpleSwapExchangeProvider(this.settingsStore)
      : super(
            pairList: CryptoCurrency.all
                .where((i) => i != CryptoCurrency.zaddr)
                .map((i) => CryptoCurrency.all
                    .where((i) => i != CryptoCurrency.zaddr)
                    .map((k) => ExchangePair(from: i, to: k, reverse: true)))
                .expand((i) => i)
                .toList());

  static const apiAuthority = 'api.simpleswap.io';
  static const getEstimatePath = '/v1/get_estimated';
  static const rangePath = '/v1/get_ranges';
  static const getExchangePath = '/v1/get_exchange';
  static const createExchangePath = '/v1/create_exchange';
  static final apiKey = DeviceInfo.instance.isMobile ? secrets.simpleSwapApiKey : secrets.simpleSwapApiKeyDesktop;

  SettingsStore settingsStore;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.simpleSwap;

  @override
  Future<double> fetchRate(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount}) async {
    try {
      if (amount == 0) {
        return 0.0;
      }
      final fromCurrency = _normalizeCryptoCurrency(from);
      final toCurrency = _normalizeCryptoCurrency(to);
      final params = <String, String>{
        'api_key': apiKey,
        'currency_from': fromCurrency,
        'currency_to': toCurrency,
        'amount': amount.toString(),
        'fixed': isFixedRateMode.toString()
      };
      final uri = Uri.https(apiAuthority, getEstimatePath, params);
      final response = await get(settingsStore, uri);

      if (response.body == "null") return 0.00;
      final data = json.decode(response.body) as String;
      return double.parse(data) / amount;
    } catch (_) {
      return 0.00;
    }
  }

  @override
  Future<bool> checkIsAvailable() async {
    final uri = Uri.https(apiAuthority, getEstimatePath, <String, String>{'api_key': apiKey});
    final response = await get(settingsStore, uri);

    return !(response.statusCode == 403);
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) async {
    final _request = request as SimpleSwapRequest;
     final headers = {
      'Content-Type': 'application/json'};
    final params = <String, String>{
      'api_key': apiKey,
    };
    final body = <String, dynamic>{
      "currency_from": _normalizeCryptoCurrency(_request.from),
      "currency_to": _normalizeCryptoCurrency(_request.to),
      "amount": _request.amount,
      "fixed": isFixedRateMode,
      "user_refund_address": _request.refundAddress,
      "address_to": _request.address
    };
    final uri = Uri.https(apiAuthority, createExchangePath, params);

    final response = await post(settingsStore, uri, headers: headers, body: json.encode(body));

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['message'] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['id'] as String;
    final inputAddress = responseJSON['address_from'] as String;
    final payoutAddress = responseJSON['address_to'] as String;
    final settleAddress = responseJSON['user_refund_address'] as String;
    final extraId = responseJSON['extra_id_from'] as String?;
    return Trade(
      id: id,
      provider: description,
      from: _request.from,
      to: _request.to,
      inputAddress: inputAddress,
      refundAddress: settleAddress,
      extraId: extraId,
      state: TradeState.created,
      amount: _request.amount,
      payoutAddress: payoutAddress,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Limits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode}) async {
    final fromCurrency = _normalizeCryptoCurrency(from);
    final toCurrency = _normalizeCryptoCurrency(to);
    final params = <String, dynamic>{
      'api_key': apiKey,
      'fixed': isFixedRateMode.toString(),
      'currency_from': fromCurrency,
      'currency_to': toCurrency,
    };
    final uri = Uri.https(apiAuthority, rangePath, params);

    final response = await get(settingsStore, uri);

    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['message'] as String;

      throw Exception('$error');
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final min = double.tryParse(responseJSON['min'] as String? ?? '');
    final max = double.tryParse(responseJSON['max'] as String? ?? '');

    return Limits(min: min, max: max);
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final params = {'api_key': apiKey, 'id': id};
    final uri = Uri.https(apiAuthority, getExchangePath, params);
    final response = await get(settingsStore, uri);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['message'] as String;

      throw TradeNotFoundException(id, provider: description, description: error);
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final fromCurrency = responseJSON['currency_from'] as String;
    final from = CryptoCurrency.fromString(fromCurrency);
    final toCurrency = responseJSON['currency_to'] as String;
    final to = CryptoCurrency.fromString(toCurrency);
    final inputAddress = responseJSON['address_from'] as String;
    final expectedSendAmount = responseJSON['expected_amount'].toString();
    final extraId = responseJSON['extra_id_from'] as String?;
    final status = responseJSON['status'] as String;
    final payoutAddress = responseJSON['address_to'] as String;
    final state = TradeState.deserialize(raw: status);

    return Trade(
      id: id,
      from: from,
      to: to,
      extraId: extraId,
      provider: description,
      inputAddress: inputAddress,
      amount: expectedSendAmount,
      state: state,
      payoutAddress: payoutAddress,
    );
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  String get title => 'SimpleSwap';

  static String _normalizeCryptoCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.zaddr:
        return 'zec';
      case CryptoCurrency.zec:
        return 'zec';
      case CryptoCurrency.bnb:
        return currency.tag!.toLowerCase();
      case CryptoCurrency.usdterc20:
        return 'usdterc20';
      case CryptoCurrency.usdttrc20:
        return 'usdttrc20';
      case CryptoCurrency.usdcpoly:
        return 'usdcpoly';
      case CryptoCurrency.usdcsol:
        return 'usdcspl';
      case CryptoCurrency.matic:
        return 'maticerc20';
      case CryptoCurrency.maticpoly:
        return 'matic';
      default:
        return currency.title.toLowerCase();
    }
  }
}
