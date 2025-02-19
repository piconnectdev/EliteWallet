package sc.elitewallet.elitewallet;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;

import com.unstoppabledomains.resolution.DomainResolution;
import com.unstoppabledomains.resolution.Resolution;

import java.security.SecureRandom;

public class MainActivity extends FlutterFragmentActivity {
    final String UTILS_CHANNEL = "sc.elite_wallet/native_utils";
    final int UNSTOPPABLE_DOMAIN_MIN_VERSION_SDK = 24;
    boolean isAppSecure = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        MethodChannel utilsChannel =
                new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                        UTILS_CHANNEL);

        utilsChannel.setMethodCallHandler(this::handle);
    }

    private void handle(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        Handler handler = new Handler(Looper.getMainLooper());

        try {
            switch (call.method) {
                case "sec_random":
                    int count = call.argument("count");
                    SecureRandom random = new SecureRandom();
                    byte bytes[] = new byte[count];
                    random.nextBytes(bytes);
                    handler.post(() -> result.success(bytes));
                    break;
                case "getUnstoppableDomainAddress":
                    int version = Build.VERSION.SDK_INT;
                    if (version >= UNSTOPPABLE_DOMAIN_MIN_VERSION_SDK) {
                        getUnstoppableDomainAddress(call, result);
                    } else {
                        handler.post(() -> result.success(""));
                    }
                    break;
                case "setIsAppSecure":
                    isAppSecure = call.argument("isAppSecure");
                    if (isAppSecure) {
                        getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
                    } else {
                        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
                    }
                    break;
                default:
                    handler.post(() -> result.notImplemented());
            }
        } catch (Exception e) {
            handler.post(() -> result.error("UNCAUGHT_ERROR", e.getMessage(), null));
        }
    }

    private void getUnstoppableDomainAddress(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        DomainResolution resolution = new Resolution();
        Handler handler = new Handler(Looper.getMainLooper());
        String domain = call.argument("domain");
        String ticker = call.argument("ticker");

        AsyncTask.execute(() -> {
            try {
                String address = resolution.getAddress(domain, ticker);
                handler.post(() -> result.success(address));
            } catch (Exception e) {
                System.out.println("Expected Address, but got " + e.getMessage());
                handler.post(() -> result.success(""));
            }
        });
    }
}