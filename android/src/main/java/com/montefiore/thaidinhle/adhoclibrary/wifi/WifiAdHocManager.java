package com.montefiore.thaidinhle.adhoclibrary.wifi;

import android.content.Context;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.util.Log;
import androidx.annotation.NonNull;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import static android.os.Looper.getMainLooper;

public class WifiAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHocPlugin][WifiManager]";

    private Context context;
    private Channel channel;
    private WifiP2pManager wifiP2pManager;

    public WifiAdHocManager(Context context) {
        this.context = context;
        this.wifiP2pManager = (WifiP2pManager) context.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = wifiP2pManager.initialize(context, getMainLooper(), null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            default:
                result.notImplemented();
                break;
        }
    }
}
