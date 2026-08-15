package com.example.apks_manager;

import android.content.Context;
import android.net.Uri;

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
import ru.solrudev.ackpine.installer.parameters.Confirmation;

public class ApksManagerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Context context;

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

            try {
                PackageInstaller packageInstaller = PackageInstaller.Companion.getInstance(context);

                List<Uri> uris = new ArrayList<>();
                for (String path : filePaths) {
                    uris.add(Uri.fromFile(new File(path)));
                }

                InstallParameters parameters = new InstallParameters.Builder()
                        .addApks(uris)
                        .setConfirmation(Confirmation.IMMEDIATE)
                        .build();

                packageInstaller.createSession(parameters).commit();
                result.success(true);

            } catch (Exception e) {
                result.error("INSTALL_ERROR", e.getMessage(), null);
            }
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        context = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {}

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        context = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        context = null;
    }
}