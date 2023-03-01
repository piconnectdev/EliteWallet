import 'dart:convert';
import 'package:elite_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:flutter/foundation.dart';
import 'package:ew_core/http_port_redirector.dart';
import 'package:ew_core/crypto_currency.dart';
import 'package:elite_wallet/anypay/any_pay_payment.dart';
import 'package:elite_wallet/anypay/any_pay_trasnaction.dart';
import 'package:elite_wallet/store/settings_store.dart';
import 'package:elite_wallet/.secrets.g.dart' as secrets;

class AnyPayApi {
	static const contentTypePaymentRequest = 'application/payment-request';
	static const contentTypePayment = 'application/payment';
	static const xPayproVersion = '2';
	static const anypayToken = secrets.anypayToken;

	AnyPayApi(this.settingsStore);

	SettingsStore settingsStore;

	static String chainByScheme(String scheme) {
		switch (scheme.toLowerCase()) {
			case 'monero':
				return CryptoCurrency.xmr.title;
			case 'bitcoin':
				return CryptoCurrency.btc.title;
			case 'litecoin':
				return CryptoCurrency.ltc.title;
			default:
				return '';
		}
	}

	static CryptoCurrency currencyByScheme(String scheme) {
		switch (scheme.toLowerCase()) {
			case 'monero':
				return CryptoCurrency.xmr;
			case 'bitcoin':
				return CryptoCurrency.btc;
			case 'litecoin':
				return CryptoCurrency.ltc;
			default:
				throw Exception('Unexpected scheme: ${scheme}');
		}
	}

	Future<AnyPayPayment> paymentRequest(String uri) async {
		final fragments = uri.split(':?r=');
		final scheme = fragments.first;
		final url = Uri.parse(fragments[1]);
  	final headers = <String, String>{
  			'Content-Type': contentTypePaymentRequest,
  			'X-Paypro-Version': xPayproVersion,
  			'Accept': '*/*',
			'x-wallet': 'cake',
			'x-wallet-token': anypayToken,};
		final body = <String, dynamic>{
			'chain': chainByScheme(scheme),
			'currency': currencyByScheme(scheme).title};
		final response = await post(settingsStore, url, headers: headers,
																body: utf8.encode(json.encode(body)));

    if (response.statusCode != 200) {
      throw Exception('Unexpected response http code: ${response.statusCode}');
		}

    final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    return AnyPayPayment.fromMap(decodedBody);
	}

	Future<AnyPayPaymentCommittedInfo> payment(
		String uri,
		{required String chain,
			required String currency,
			required List<AnyPayTransaction> transactions}) async {
  	final headers = <String, String>{
  			'Content-Type': contentTypePayment,
  			'X-Paypro-Version': xPayproVersion,
  			'Accept': '*/*',
			'x-wallet': 'cake',
			'x-wallet-token': anypayToken,};
		final body = <String, dynamic>{
			'chain': chain,
			'currency': currency,
			'transactions': transactions.map((tx) => {'tx': tx.tx, 'tx_hash': tx.id, 'tx_key': tx.key}).toList()};
		final response = await post(settingsStore, Uri.parse(uri), headers: headers, body: utf8.encode(json.encode(body)));
		if (response.statusCode == 400) {
			final decodedBody = json.decode(response.body) as Map<String, dynamic>;
			throw Exception(decodedBody['message'] as String? ?? 'Unexpected response\nError code: 400');
		}

		if (response.statusCode != 200) {
			throw Exception('Unexpected response');
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		return AnyPayPaymentCommittedInfo(
			uri: uri,
			currency: currency,
			chain: chain,
			transactions: transactions,
			memo: decodedBody['memo'] as String);
	}
}