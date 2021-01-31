package com.montefiore.thaidinhle.adhoclibrary.wifi;

import android.content.Context;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.WifiManager;
import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

import static android.os.Looper.getMainLooper;

public class WifiAdHocManager implements MethodCallHandler {
    private static final String CHANNEL_NAME = "ad.hoc.lib/plugin.wifi.channel";
    
    private Context context;
    private Channel channel;
    private MethodChannel methodChannel;
    private String initialName;
    private String currentAdapterName;
    private WifiP2pManager wifiP2pManager;

    public WifiAdHocManager(Context context) {
        this.context = context;
        this.wifiP2pManager = (WifiP2pManager) context.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = wifiP2pManager.initialize(context, getMainLooper(), null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
      switch (call.method) {
        case "resetDeviceName":
            result.success(resetDeviceName());
            break;
        case "updateDeviceName":
            final String name = call.arguments();
            result.success(updateDeviceName(name));
            break;
        case "getAdapterName":
            result.success(getAdapterName());
            break;

        case "isWifiEnabled":
            result.success(isWifiEnabled());
            break;

        default:
          result.notImplemented();
          break;
      }
    }

    public void initMethodCallHandler(BinaryMessenger messenger) {
        methodChannel = new MethodChannel(messenger, CHANNEL_NAME);
        methodChannel.setMethodCallHandler(this);
    }

    public void setMethodCallHandler(MethodCallHandler handler) {
        methodChannel.setMethodCallHandler(handler);
    }

    private boolean isWifiEnabled() {
        WifiManager wifiManager = (WifiManager) context
            .getApplicationContext()
            .getSystemService(Context.WIFI_SERVICE);
        return wifiManager != null && wifiManager.isWifiEnabled();
    }

    private boolean resetDeviceName() {
        return (initialName != null) ? updateDeviceName(initialName) : false;
    }

    private boolean updateDeviceName(String name) {
        try {
            Method method = wifiP2pManager.getClass().getMethod(
                "setDeviceName",
                new Class[] {
                    channel.getClass(),
                    String.class,
                    WifiP2pManager.ActionListener.class
                }
            );

            method.invoke(wifiP2pManager, channel, name, null);
            currentAdapterName = name;

            return true;
        } catch (IllegalAccessException e) {
            return false;
        } catch (InvocationTargetException e) {
            return false;
        } catch (NoSuchMethodException e) {
            return false;
        }
    }

    private String getAdapterName() {
        return currentAdapterName;
    }
}
