package com.montefiore.thaidinhle.adhoc_plugin.wifi;

import android.content.Context;
import android.content.IntentFilter;
import android.net.wifi.WifiManager;
import android.net.wifi.WpsInfo;
import android.net.wifi.p2p.WifiP2pConfig;
import android.net.wifi.p2p.WifiP2pGroup;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.WifiManager;
import android.util.Log;
import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;

import static android.net.wifi.p2p.WifiP2pManager.BUSY;
import static android.net.wifi.p2p.WifiP2pManager.ERROR;
import static android.net.wifi.p2p.WifiP2pManager.P2P_UNSUPPORTED;
import static android.os.Looper.getMainLooper;


public class WifiAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHocPlugin][WifiAdHocManager]";
    private static final String METHOD_NAME = "ad.hoc.lib/wifi.method.channel";
    private static final String EVENT_NAME = "ad.hoc.lib/wifi.event.channel";

    private boolean verbose;
    private boolean registered;
    private Channel channel;
    private Context context;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventSink eventSink;
    private String initialName;
    private String currentAdapterName;
    private WifiBroadcastReceiver receiver;
    private WifiP2pManager wifiP2pManager;

    public WifiAdHocManager(Context context) {
        this.verbose = false;
        this.registered = false;
        this.context = context;
        this.wifiP2pManager = 
            (WifiP2pManager) context.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = wifiP2pManager.initialize(context, getMainLooper(), null);
    }

/*------------------------------Override methods------------------------------*/

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
        case "currentName":
            final String currentName = call.arguments();
            currentAdapterName = currentName;
            break;
        case "updateDeviceName":
            final String name = call.arguments();
            result.success(updateDeviceName(name));
            break;
        case "resetDeviceName":
            result.success(resetDeviceName());
            break;
        case "getMacAddress":
            result.success(getMacAddress());
            break;
        case "register":
            register();
            break;
        case "unregister":
            unregister();
            break;
        case "discovery":
            startDiscovery();
            break;
        case "connect":
            final String remoteAddress = call.arguments();
            connect(remoteAddress);
            break;
        case "removeGroup":
            removeGroup();
            break;

        default:
          result.notImplemented();
          break;
      }
    }

/*--------------------------------Public methods------------------------------*/

    public void initMethodCallHandler(BinaryMessenger messenger) {
        if (verbose) Log.d(TAG, "initMethodCallHandler()");

        methodChannel = new MethodChannel(messenger, METHOD_NAME);
        methodChannel.setMethodCallHandler(this);
        eventChannel = new EventChannel(messenger, EVENT_NAME);
        eventChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
              eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
              eventSink = null;
              eventChannel.setStreamHandler(null);
              eventChannel = null;
            }
        });
    }

    public void close() {
        if (verbose) Log.d(TAG, "close()");
        unregister();
        methodChannel.setMethodCallHandler(null);
    }

/*-------------------------------Private methods------------------------------*/

    private void setVerbose(boolean verbose) {
        if (verbose) Log.d(TAG, "setVerbose()");
        this.verbose = verbose;
    }

    private void register() {
        if (verbose) Log.d(TAG, "register()");

        final IntentFilter filter = new IntentFilter();

        filter.addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION);
        filter.addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION);
        filter.addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION);
        filter.addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION);
    
        receiver = new WifiBroadcastReceiver(channel, eventSink, wifiP2pManager);
        receiver.setVerbose(verbose);

        context.registerReceiver(receiver, filter);

        registered = true;
    }

    private void unregister() {
        if (verbose) Log.d(TAG, "unregister()");

        if (registered) {
            context.unregisterReceiver(receiver);
            registered = false;
        }
    }

    private boolean isWifiEnabled() {
        if (verbose) Log.d(TAG, "isWifiEnabled()");

        WifiManager wifiManager = (WifiManager) context
            .getApplicationContext()
            .getSystemService(Context.WIFI_SERVICE);

        return wifiManager != null && wifiManager.isWifiEnabled();
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

    private String getMacAddress() {
        try {
            ArrayList<NetworkInterface> networkInterfaces = 
                Collections.list(NetworkInterface.getNetworkInterfaces());

            for (NetworkInterface networkInterface : networkInterfaces) {
               if (networkInterface.getName().compareTo("p2p-wlan0-0") == 0) {
                byte[] mac = networkInterface.getHardwareAddress();
                if (mac == null) {
                    return "";
                }

                StringBuilder sb = new StringBuilder();
                for (byte b : mac) {
                    if (sb.length() > 0)
                        sb.append(':');
                    sb.append(String.format("%02x", b));
                }

                return sb.toString();
               }
            }
        } catch (SocketException exception) {
            if (verbose) 
                Log.d(TAG, "Error while fetching MAC address" + exception.toString());
        }

        return "";
    }

    private String errorCode(int reasonCode) {
        switch (reasonCode) {
            case ERROR:
                return "P2P internal error";
            case P2P_UNSUPPORTED:
                return "P2P is not supported";
            case BUSY:
                return "P2P is busy";
        }

        return "Unknown error";
    }

/*------------------------------WiFi P2P methods------------------------------*/

    private void startDiscovery() {
        wifiP2pManager.discoverPeers(channel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                if (verbose) 
                    Log.d(TAG, "startDiscovery(): success");
            }

            @Override
            public void onFailure(int reasonCode) {
                if (verbose) 
                    Log.d(TAG, "startDiscovery(): failure -> " + errorCode(reasonCode));
            }
        });
    }

    private void connect(final String remoteAddress) {
        final WifiP2pConfig config = new WifiP2pConfig();
        config.deviceAddress = remoteAddress.toLowerCase();
        config.wps.setup = WpsInfo.PBC;

        wifiP2pManager.connect(channel, config, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                if (verbose) 
                    Log.d(TAG, "connect(): success");
            }

            @Override
            public void onFailure(int reasonCode) {
                if (verbose) 
                    Log.e(TAG, "connect(): failure -> " + errorCode(reasonCode));
            }
        });
    }

    private void removeGroup() {
        wifiP2pManager.requestGroupInfo(channel, new WifiP2pManager.GroupInfoListener() {
            @Override
            public void onGroupInfoAvailable(WifiP2pGroup group) {
                if (group != null) {
                    wifiP2pManager.removeGroup(channel, new WifiP2pManager.ActionListener() {
                        @Override
                        public void onSuccess() {
                            if (verbose) 
                                Log.d(TAG, "removeGroup(): success");
                        }

                        @Override
                        public void onFailure(int reason) {
                            if (verbose) 
                                Log.e(TAG, "removeGroup(): failure -> " + errorCode(reason));
                        }
                    });
                }
            }
        });
    }
}
