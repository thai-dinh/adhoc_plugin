package com.thaidinhle.adhoclibrary;

import android.content.Context;
import android.net.wifi.p2p.WifiP2pManager;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class WifiAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHoc][WifiManager]";

    private final boolean verbose;
    private Context context;

    WifiAdHocManager(Boolean verbose, Context context) {
        this.verbose = verbose;
        this.context = context;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "enable":
                wifiAdapterState(true);
                break;
            case "disable":
                wifiAdapterState(false);
                break;
            default:
                break;
        }
    }

    private void wifiAdapterState(boolean state) {
        WifiManager wifi = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (wifi != null) {
            wifi.setWifiEnabled(state);
        }
    }
}
