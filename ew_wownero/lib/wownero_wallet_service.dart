import 'dart:io';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:ew_core/monero_wallet_utils.dart';
import 'package:ew_core/pathForWallet.dart';
import 'package:ew_core/wallet_base.dart';
import 'package:ew_core/wallet_credentials.dart';
import 'package:ew_core/wallet_info.dart';
import 'package:ew_core/wallet_service.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:ew_wownero/api/exceptions/wallet_opening_exception.dart';
import 'package:ew_wownero/api/wallet_manager.dart' as wownero_wallet_manager;
import 'package:ew_wownero/wownero_wallet.dart';
import 'package:hive/hive.dart';

class WowneroNewWalletCredentials extends WalletCredentials {
  WowneroNewWalletCredentials(
      {required String name, String? password, this.language, int seedWordsLength = 14})
      : super(name: name, password: password);

  final String? language;
  final int seedWordsLength = 14;
}

class WowneroRestoreWalletFromSeedCredentials extends WalletCredentials {
  WowneroRestoreWalletFromSeedCredentials(
      {required String name, String? password, int? height, this.mnemonic})
      : super(name: name, password: password, height: height);

  final String? mnemonic;
}

class WowneroWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class WowneroRestoreWalletFromKeysCredentials extends WalletCredentials {
  WowneroRestoreWalletFromKeysCredentials(
      {required String name,
      String? password,
      this.language,
      this.address,
      this.viewKey,
      this.spendKey,
      int? height})
      : super(name: name, password: password, height: height);

  final String? language;
  final String? address;
  final String? viewKey;
  final String? spendKey;
}

class WowneroWalletService extends WalletService<
    WowneroNewWalletCredentials,
    WowneroRestoreWalletFromSeedCredentials,
    WowneroRestoreWalletFromKeysCredentials> {
  WowneroWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.wownero;

  @override
  Future<WowneroWallet> create(WowneroNewWalletCredentials credentials,
      {int seedWordsLength = 14}) async {
    try {
      final path =
          await pathForWallet(name: credentials.name!, type: getType());
      await wownero_wallet_manager.createWallet(
          path: path,
          password: credentials.password,
          language: credentials.language,
          seedWordsLength: seedWordsLength);
      final wallet = WowneroWallet(walletInfo: credentials.walletInfo!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('WowneroWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      return wownero_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('WowneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<WowneroWallet> openWallet(String name, String password) async {
    try {
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) {
        await repairOldAndroidWallet(name);
      }

      await wownero_wallet_manager
          .openWalletAsync({'path': path, 'password': password});
      final walletInfo = walletInfoSource.values.firstWhereOrNull(
          (info) => info.id == WalletBase.idFor(name, getType()))!;
      final wallet = WowneroWallet(walletInfo: walletInfo);
      final isValid = wallet.walletAddresses.validate();

      if (!isValid) {
        await restoreOrResetWalletFiles(name);
        wallet.close();
        return openWallet(name, password);
      }

      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.

      if ((e.toString().contains('bad_alloc') ||
              (e is WalletOpeningException &&
                  (e.message == 'std::bad_alloc' ||
                      e.message!.contains('bad_alloc')))) ||
          (e.toString().contains('does not correspond') ||
              (e is WalletOpeningException &&
                  e.message!.contains('does not correspond')))) {
        await restoreOrResetWalletFiles(name);
        return openWallet(name, password);
      }

      rethrow;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }
  }

  @override
  Future<WowneroWallet> restoreFromKeys(
      WowneroRestoreWalletFromKeysCredentials credentials) async {
    try {
      final path =
          await pathForWallet(name: credentials.name!, type: getType());
      await wownero_wallet_manager.restoreFromKeys(
          path: path,
          password: credentials.password,
          language: credentials.language,
          restoreHeight: credentials.height,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);
      final wallet = WowneroWallet(walletInfo: credentials.walletInfo!);
      wallet.walletInfo.isRecovery = true;
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('WowneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<WowneroWallet> restoreFromSeed(
      WowneroRestoreWalletFromSeedCredentials credentials) async {
    try {
      final path =
          await pathForWallet(name: credentials.name!, type: getType());
      await wownero_wallet_manager.restoreFromSeed(
          path: path,
          password: credentials.password,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height);
      final wallet = WowneroWallet(walletInfo: credentials.walletInfo!);
      wallet.walletInfo.isRecovery = true;

      String seedString = credentials.mnemonic ?? '';
      int seedWordsLength = seedString.split(' ').length;
      if (seedWordsLength == 14) {
        wallet.walletInfo.restoreHeight =
            wallet.getSeedHeight(credentials.mnemonic!);
      } else {
        wallet.walletInfo.restoreHeight = 0;
        // TODO use an alternative to wow_seed's get_seed_height
      }

      await wallet.init();
      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('WowneroWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<void> repairOldAndroidWallet(String name) async {
    try {
      if (!Platform.isAndroid) {
        return;
      }

      final oldAndroidWalletDirPath =
          await outdatedAndroidPathForWalletDir(name: name);
      final dir = Directory(oldAndroidWalletDirPath);

      if (!dir.existsSync()) {
        return;
      }

      final newWalletDirPath =
          await pathForWalletDir(name: name, type: getType());

      dir.listSync().forEach((f) {
        final file = File(f.path);
        final name = f.path.split('/').last;
        final newPath = newWalletDirPath + '/$name';
        final newFile = File(newPath);

        if (!newFile.existsSync()) {
          newFile.createSync();
        }
        newFile.writeAsBytesSync(file.readAsBytesSync());
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
