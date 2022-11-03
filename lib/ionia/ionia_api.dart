import 'dart:convert';
import 'package:elite_wallet/ionia/ionia_merchant.dart';
import 'package:elite_wallet/ionia/ionia_order.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/http_port_redirector.dart';
import 'package:elite_wallet/ionia/ionia_user_credentials.dart';
import 'package:elite_wallet/ionia/ionia_virtual_card.dart';
import 'package:elite_wallet/ionia/ionia_category.dart';
import 'package:elite_wallet/ionia/ionia_gift_card.dart';
import 'package:elite_wallet/store/settings_store.dart';

class IoniaApi {
	static const baseUri = 'api.ionia.io';
	static const pathPrefix = 'elite';
	static const requestedUUIDHeader = 'requestedUUID';
	static final createUserUri = Uri.https(baseUri, '/$pathPrefix/CreateUser');
	static final verifyEmailUri = Uri.https(baseUri, '/$pathPrefix/VerifyEmail');
	static final signInUri = Uri.https(baseUri, '/$pathPrefix/SignIn');
	static final createCardUri = Uri.https(baseUri, '/$pathPrefix/CreateCard');
	static final getCardsUri = Uri.https(baseUri, '/$pathPrefix/GetCards');
	static final getMerchantsUrl = Uri.https(baseUri, '/$pathPrefix/GetMerchants');
	static final getMerchantsByFilterUrl = Uri.https(baseUri, '/$pathPrefix/GetMerchantsByFilter');
  	static final getPurchaseMerchantsUrl = Uri.https(baseUri, '/$pathPrefix/PurchaseGiftCard');
  	static final getCurrentUserGiftCardSummariesUrl = Uri.https(baseUri, '/$pathPrefix/GetCurrentUserGiftCardSummaries');
  	static final changeGiftCardUrl = Uri.https(baseUri, '/$pathPrefix/ChargeGiftCard');
  	static final getGiftCardUrl = Uri.https(baseUri, '/$pathPrefix/GetGiftCard');
  	static final getPaymentStatusUrl = Uri.https(baseUri, '/$pathPrefix/PaymentStatus');

	IoniaApi(this.settingsStore);

	SettingsStore settingsStore;

	// Create user

	Future<String> createUser(String email, {@required String clientId}) async {
		final headers = <String, String>{'clientId': clientId};
		final query = <String, String>{'emailAddress': email};
		final uri = createUserUri.replace(queryParameters: query);
		final response = await put(settingsStore, uri, headers: headers);
		
		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['ErrorMessage'] as String);
		}

		return data['username'] as String;
	}

	// Verify email

	Future<IoniaUserCredentials> verifyEmail({
		@required String username,
		@required String email,
		@required String code,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'EmailAddress': email};
		final query = <String, String>{'verificationCode': code};
		final uri = verifyEmailUri.replace(queryParameters: query);
		final response = await put(settingsStore, uri, headers: headers);

		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(bodyJson['ErrorMessage'] as String);
		}
		
		final password = data['password'] as String;
		username = data['username'] as String;
		return IoniaUserCredentials(username, password);
	}

	// Sign In

	Future<String> signIn(String email, {@required String clientId}) async {
		final headers = <String, String>{'clientId': clientId};
		final query = <String, String>{'emailAddress': email};
		final uri = signInUri.replace(queryParameters: query);
		final response = await put(settingsStore, uri, headers: headers);
		
		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['ErrorMessage'] as String);
		}

		return data['username'] as String;
	}

	// Get virtual card

	Future<IoniaVirtualCard> getCards({
		@required String username,
		@required String password,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(settingsStore, getCardsUri, headers: headers);

		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['message'] as String);
		}

		final virtualCard = data['VirtualCard'] as Map<String, Object>;
		return IoniaVirtualCard.fromMap(virtualCard);
	}

	// Create virtual card

	Future<IoniaVirtualCard> createCard({
		@required String username,
		@required String password,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(
			settingsStore, createCardUri, headers: headers);

		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['message'] as String);
		}

		return IoniaVirtualCard.fromMap(data);
	}

	// Get Merchants

	Future<List<IoniaMerchant>> getMerchants({
		@required String username,
		@required String password,
		@required String clientId}) async {
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(
			settingsStore, getMerchantsUrl, headers: headers);

		if (response.statusCode != 200) {
			return [];
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;
    
		if (!isSuccessful) {
			return [];
		}

		final data = decodedBody['Data'] as List<dynamic>;
		return data.map((dynamic e) {
			try {
				final element = e as Map<String, dynamic>;
				return IoniaMerchant.fromJsonMap(element);
			} catch(_) {
				return null;
			} 
		}).where((e) => e != null)
		.toList();
	}

	// Get Merchants By Filter

	Future<List<IoniaMerchant>> getMerchantsByFilter({
		@required String username,
		@required String password,
		@required String clientId,
		String search,
		List<IoniaCategory> categories,
		int merchantFilterType = 0}) async {
		// MerchantFilterType: {All = 0, Nearby = 1, Popular = 2, Online = 3, MyFaves = 4, Search = 5}
	    
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{'MerchantFilterType': merchantFilterType};

		if (search != null) {
			body['SearchCriteria'] = search;
		}

		if (categories != null) {
			body['Categories'] = categories
				.map((e) => e.ids)
				.expand((e) => e)
				.toList();
		}

		final response = await post(settingsStore, getMerchantsByFilterUrl,
																headers: headers, body: json.encode(body));

		if (response.statusCode != 200) {
			return [];
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;

		if (!isSuccessful) {
			return [];
		}

		final data = decodedBody['Data'] as List<dynamic>;
		return data.map((dynamic e) {
			try {
				final element = e['Merchant'] as Map<String, dynamic>;
				return IoniaMerchant.fromJsonMap(element);
			} catch(_) {
				return null;
			}
		}).where((e) => e != null)
		.toList();
	}

	// Purchase Gift Card

	Future<IoniaOrder> purchaseGiftCard({
		@required String requestedUUID,
		@required String merchId,
		@required double amount,
		@required String currency,
		@required String username,
		@required String password,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			requestedUUIDHeader: requestedUUID,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{
			'Amount': amount,
		    'Currency': currency,
		    'MerchantId': merchId};
		final response = await post(settingsStore, getPurchaseMerchantsUrl,
																headers: headers, body: json.encode(body));

    	if (response.statusCode != 200) {
			throw Exception('Unexpected response');
		}

    	final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;

		if (!isSuccessful) {
			throw Exception(decodedBody['ErrorMessage'] as String);
		}

		final data = decodedBody['Data'] as Map<String, dynamic>;
    	return IoniaOrder.fromMap(data);
	}

	// Get Current User Gift Card Summaries

	Future<List<IoniaGiftCard>> getCurrentUserGiftCardSummaries({
		@required String username,
		@required String password,
		@required String clientId}) async {
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(
			settingsStore, getCurrentUserGiftCardSummariesUrl, headers: headers);

		if (response.statusCode != 200) {
			return [];
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;
    
		if (!isSuccessful) {
			return [];
		}

		final data = decodedBody['Data'] as List<dynamic>;
		return data.map((dynamic e) {
			try {
				final element = e as Map<String, dynamic>;
				return IoniaGiftCard.fromJsonMap(element);
			} catch(e) {
				return null;
			}
		}).where((e) => e != null)
		.toList();
	}

	// Charge Gift Card

	Future<void> chargeGiftCard({
		@required String username,
		@required String password,
		@required String clientId,
		@required int giftCardId,
		@required double amount}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{
			'Id': giftCardId,
			'Amount': amount};
		final response = await post(
			settingsStore,
			changeGiftCardUrl,
			headers: headers,
			body: json.encode(body));

		if (response.statusCode != 200) {
			throw Exception('Failed to update Gift Card with ID ${giftCardId};Incorrect response status: ${response.statusCode};');
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;

		if (!isSuccessful) {
			final data = decodedBody['Data'] as Map<String, dynamic>;
			final msg = data['Message'] as String ?? '';

			if (msg.isNotEmpty) {
				throw Exception(msg);
			}

			throw Exception('Failed to update Gift Card with ID ${giftCardId};');
		}
	}

	// Get Gift Card

	Future<IoniaGiftCard> getGiftCard({
		@required String username,
		@required String password,
		@required String clientId,
		@required int id}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{'Id': id};
		final response = await post(
			settingsStore,
			getGiftCardUrl,
			headers: headers,
			body: json.encode(body));

		if (response.statusCode != 200) {
			throw Exception('Failed to get Gift Card with ID ${id};Incorrect response status: ${response.statusCode};');
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;

		if (!isSuccessful) {
			final msg = decodedBody['ErrorMessage'] as String ?? '';

			if (msg.isNotEmpty) {
				throw Exception(msg);
			}

			throw Exception('Failed to get Gift Card with ID ${id};');
		}

		final data = decodedBody['Data'] as Map<String, dynamic>;
		return IoniaGiftCard.fromJsonMap(data);
	}

	// Payment Status

	Future<int> getPaymentStatus({
		@required String username,
		@required String password,
		@required String clientId,
		@required String orderId,
		@required String paymentId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{
			'order_id': orderId,
			'paymentId': paymentId};
		final response = await post(
			settingsStore,
			getPaymentStatusUrl,
			headers: headers,
			body: json.encode(body));

		if (response.statusCode != 200) {
			throw Exception('Failed to get Payment Status for order_id ${orderId} paymentId ${paymentId};Incorrect response status: ${response.statusCode};');
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;

		if (!isSuccessful) {
			final msg = decodedBody['ErrorMessage'] as String ?? '';

			if (msg.isNotEmpty) {
				throw Exception(msg);
			}

			throw Exception('Failed to get Payment Status for order_id ${orderId} paymentId ${paymentId}');
		}

		final data = decodedBody['Data'] as Map<String, dynamic>;
		return data['gift_card_id'] as int;
	}
}