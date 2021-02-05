package com.montefiore.thaidinhle.adhoclibrary.wifi;

import android.content.Context;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.WifiManager;
import android.util.Log;
import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;

import static android.os.Looper.getMainLooper;

public class WifiAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHoc][WifiManager]";
    private static final String CHANNEL_NAME = "ad.hoc.lib/plugin.wifi.channel";

    private boolean verbose;
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
        case "setVerbose":
            final boolean verbose = call.arguments();
            setVerbose(verbose);
            break;
        case "isWifiEnabled":
            result.success(isWifiEnabled());
            break;
        case "getAdapterName":
            result.success(getAdapterName());
            break;
        case "updateDeviceName":
            final String name = call.arguments();
            result.success(updateDeviceName(name));
            break;
        case "resetDeviceName":
            result.success(resetDeviceName());
            break;
        case "getOwnIpAddress":
            try {
                byte[] ipAddressByte = getLocalIPAddress();
                if (ipAddressByte != null) {
                    result.success(getDottedDecimalIP(ipAddressByte));
                } else {
                    result.success(null);
                }
            } catch (SocketException exception) {
                result.error("SocketException", "getOwnIpAddress() failed", null);
            }
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

    public void setVerbose(boolean verbose) {
        if (verbose) Log.d(TAG, "setVerbose()");
        this.verbose = verbose;
    }

    private boolean isWifiEnabled() {
        if (verbose) Log.d(TAG, "isWifiEnabled()");

        WifiManager wifiManager = (WifiManager) context
            .getApplicationContext()
            .getSystemService(Context.WIFI_SERVICE);
        return wifiManager != null && wifiManager.isWifiEnabled();
    }

    private String getAdapterName() {
        return currentAdapterName;
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

    private boolean resetDeviceName() {
        return (initialName != null) ? updateDeviceName(initialName) : false;
    }

    private byte[] getLocalIPAddress() throws SocketException {
        if (verbose) Log.d(TAG, "getLocalIPAddress()");
        for (Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces(); en.hasMoreElements(); ) {
            NetworkInterface intf = en.nextElement();
            for (Enumeration<InetAddress> enumIpAddr = intf.getInetAddresses(); enumIpAddr.hasMoreElements(); ) {
                InetAddress inetAddress = enumIpAddr.nextElement();
                if (!inetAddress.isLoopbackAddress() && inetAddress.toString().contains("192.168.49")) {
                    if (inetAddress instanceof Inet4Address) {
                        return inetAddress.getAddress();
                    }
                }
            }
        }

        return null;
    }

    private String getDottedDecimalIP(byte[] ipAddressByte) {
        if (verbose) Log.d(TAG, "getDottedDecimalIP()");
        StringBuilder ipAddressString = new StringBuilder();
        for (int i = 0; i < ipAddressByte.length; i++) {
            if (i > 0) {
                ipAddressString.append(".");
            }
            ipAddressString.append(ipAddressByte[i] & 0xFF);
        }

        if (verbose) Log.d(TAG, ipAddressString.toString());
        return ipAddressString.toString();
    }
}
