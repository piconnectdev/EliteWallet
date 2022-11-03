import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/wallet_type.dart';
import 'dart:async';

part 'wallet_info.g.dart';

@HiveType(typeId: WalletInfo.typeId)
class WalletInfo extends HiveObject {
  WalletInfo(this.id, this.name, this.type, this.isRecovery, this.restoreHeight,
      this.timestamp, this.dirPath, this.path, this.address, this.yatEid,
        this.yatLastUsedAddressRaw, this.showIntroElitePayCard)
      : _yatLastUsedAddressController = StreamController<String>.broadcast();

  factory WalletInfo.external(
      {@required String id,
      @required String name,
      @required WalletType type,
      @required bool isRecovery,
      @required int restoreHeight,
      @required DateTime date,
      @required String dirPath,
      @required String path,
      @required String address,
      String yatEid ='',
      String yatLastUsedAddressRaw = '',
      bool showIntroElitePayCard}) {
    return WalletInfo(id, name, type, isRecovery, restoreHeight,
        date.millisecondsSinceEpoch ?? 0, dirPath, path, address,
        yatEid, yatLastUsedAddressRaw, showIntroElitePayCard);
  }

  static const typeId = 4;
  static const boxName = 'WalletInfo';

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  WalletType type;

  @HiveField(3)
  bool isRecovery;

  @HiveField(4)
  int restoreHeight;

  @HiveField(5)
  int timestamp;

  @HiveField(6)
  String dirPath;

  @HiveField(7)
  String path;

  @HiveField(8)
  String address;

  @HiveField(10)
  Map<String, String> addresses;

  @HiveField(11)
  String yatEid;

  @HiveField(12)
  String yatLastUsedAddressRaw;

  @HiveField(13)
  bool showIntroElitePayCard;

  String get yatLastUsedAddress => yatLastUsedAddressRaw;

  set yatLastUsedAddress(String address) {
    yatLastUsedAddressRaw = address;
    _yatLastUsedAddressController.add(address);
  }

  String get yatEmojiId => yatEid ?? '';

  bool get isShowIntroElitePayCard {
    if(showIntroElitePayCard == null) {
      return type != WalletType.haven;
    }
    return showIntroElitePayCard;
  }

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Stream<String> get yatLastUsedAddressStream => _yatLastUsedAddressController.stream;

  StreamController<String> _yatLastUsedAddressController;
}
