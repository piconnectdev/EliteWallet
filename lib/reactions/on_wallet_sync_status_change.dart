import 'package:elite_wallet/di.dart';
import 'package:elite_wallet/entities/update_haven_rate.dart';
import 'package:elite_wallet/entities/wake_lock.dart';
import 'package:elite_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:ew_core/transaction_history.dart';
import 'package:ew_core/wallet_base.dart';
import 'package:ew_core/balance.dart';
import 'package:ew_core/transaction_info.dart';
import 'package:ew_core/sync_status.dart';
import 'package:flutter/services.dart';

ReactionDisposer? _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
            TransactionInfo> wallet,
    FiatConversionStore fiatConversionStore) {
  final _wakeLock = getIt.get<WakeLock>();
  _onWalletSyncStatusChangeReaction?.reaction.dispose();
  _onWalletSyncStatusChangeReaction =
      reaction((_) => wallet.syncStatus, (SyncStatus status) async {
    try {
      if (status is ConnectedSyncStatus) {
        await wallet.startSync();

        if (wallet.type == WalletType.haven) {
          await updateHavenRate(fiatConversionStore);
        }
      }
      if (status is SyncingSyncStatus) {
        await _wakeLock.enableWake();
      }
      if (status is SyncedSyncStatus || status is FailedSyncStatus) {
        await _wakeLock.disableWake();
      }
    } catch(e) {
      print(e.toString());
    }
  });
}
