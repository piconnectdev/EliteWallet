import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ew_bitcoin/bitcoin_amount_format.dart';
import 'package:ew_core/balance.dart';

class ElectrumBalance extends Balance {
  const ElectrumBalance({required this.confirmed, required this.unconfirmed, required this.frozen})
      : super(confirmed, unconfirmed);

  static ElectrumBalance? fromJSON(String? jsonSource) {
    if (jsonSource == null) {
      return null;
    }

    final decoded = json.decode(jsonSource) as Map;

    return ElectrumBalance(
        confirmed: decoded['confirmed'] as int? ?? 0,
        unconfirmed: decoded['unconfirmed'] as int? ?? 0,
        frozen: decoded['frozen'] as int? ?? 0);
  }

  final int confirmed;
  final int unconfirmed;
  final int frozen;

  @override
  String get formattedAvailableBalance => bitcoinAmountToString(amount: confirmed - frozen);

  @override
  String get formattedAdditionalBalance => bitcoinAmountToString(amount: unconfirmed);

  String get formattedFrozenBalance {
    final frozenFormatted = bitcoinAmountToString(amount: frozen);
    return frozenFormatted == '0.0' ? '' : frozenFormatted;
  }

  String toJSON() =>
      json.encode({'confirmed': confirmed, 'unconfirmed': unconfirmed, 'frozen': frozen});
}
