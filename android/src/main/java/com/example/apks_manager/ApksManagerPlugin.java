package com.example.apks_manager;

import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import ru.solrudev.ackpine.installer.PackageInstaller;
import ru.solrudev.ackpine.installer.parameters.InstallParameters;
import ru.solrudev.ackpine.session.parameters.Confirmation;
import ru.solrudev.ackpine.DisposableSubscriptionContainer;
import ru.solrudev.ackpine.session.Session;

public class ApksManagerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Context context;
    
    // Class-level container for memory management
    private final DisposableSubscriptionContainer subscriptions = new DisposableSubscriptionContainer();
    
    // Handler to safely pass data back to Flutter's Main UI Thread
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "apks_manager");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("installSplitApks")) {
            List<String> filePaths = call.argument("filePaths");

            if (filePaths == null || filePaths.isEmpty()) {
                result.error("INVALID_ARGS", "File paths list is empty", null);
                return;
            }

            if (context == null) {
                result.error("NO_CONTEXT", "Android context is null", null);
                return;
            }

            try {
                PackageInstaller packageInstaller = PackageInstaller.getInstance(context);

                List<Uri> uris = new ArrayList<>();
                for (String path : filePaths) {
                    uris.add(Uri.fromFile(new File(path)));
                }

                InstallParameters parameters = new InstallParameters.Builder(uris.get(0))
                        .addApks(uris.subList(1, uris.size()))
                        .setConfirmation(Confirmation.IMMEDIATE)
                        .build();

                // 1. Create the session
                var session = packageInstaller.createSession(parameters);

                // 2. Bind the listener using the class-level container
                // 3. Use mainHandler to safely send the result back to Flutter
                Session.TerminalStateListener.bind(session, subscriptions)
                        .addOnSuccessListener(sessionId -> {
                            mainHandler.post(() -> result.success(true));
                        })
                        .addOnCancelListener(sessionId -> {
                            mainHandler.post(() -> result.error("CANCELLED", "Installation was cancelled", null));
                        })
                        .addOnFailureListener((sessionId, failure) -> {
                            mainHandler.post(() -> result.error("INSTALL_ERROR", failure.getMessage(), null));
                        });

            } catch (Exception e) {
                result.error("INSTALL_ERROR", e.getMessage(), null);
            }
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        context = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        context = null;
        subscriptions.clear(); // Prevent memory leaks on config changes
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        context = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        context = null;
        subscriptions.clear(); // Prevent memory leaks when UI is destroyed
    }
}