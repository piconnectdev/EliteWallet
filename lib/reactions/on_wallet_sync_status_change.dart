import 'package:elite_wallet/entities/update_haven_rate.dart';
import 'package:elite_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:ew_core/transaction_history.dart';
import 'package:ew_core/wallet_base.dart';
import 'package:ew_core/balance.dart';
import 'package:ew_core/transaction_info.dart';
import 'package:ew_core/sync_status.dart';
import 'package:wakelock/wakelock.dart';

ReactionDisposer? _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
            TransactionInfo> wallet,
    FiatConversionStore fiatConversionStore) {
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
        await Wakelock.enable();
      }
      if (status is SyncedSyncStatus || status is FailedSyncStatus) {
        await Wakelock.disable();
      }
    } catch(e) {
      print(e.toString());
    }
  });
}
