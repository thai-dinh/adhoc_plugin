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

/**
 * Class managing the Wi-Fi discovery and the pairing with other Wi-Fi devices.
 * 
 * NOTE: Most of the following source code has been borrowed and adapted from 
 * the original codebase provided by Gaulthier Gain, which can be found at:
 * https://github.com/gaulthiergain/AdHocLib
 */
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

    /**
     * Default constructor
     *
     * @param context   Context object giving global information about the 
     *                  application environment.
     */
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

    /**
     * Method allowing to initialize the method call handler.
     * 
     * @param messenger BinaryMessenger object, which sends binary data across 
     *                  the Flutter platform barrier.
     */
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

    /** 
     * Method allowing to release the ressources used.
     */
    public void close() {
        if (verbose) Log.d(TAG, "close()");

        unregister();
        methodChannel.setMethodCallHandler(null);
    }

/*-------------------------------Private methods------------------------------*/

    /** 
     * Method allowing to update the verbose/debug mode.
     * 
     * @param verbose   Boolean value representing the sate of the verbose/debug 
     *                  mode.
     */
    private void setVerbose(boolean verbose) {
        if (verbose) Log.d(TAG, "setVerbose()");
        this.verbose = verbose;
    }

    /** 
     * Method allowing to register the broadcast receiver.
     */
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

    /** 
     * Method allowing to unregister the broadcast receiver.
     */
    private void unregister() {
        if (verbose) Log.d(TAG, "unregister()");

        if (registered) {
            context.unregisterReceiver(receiver);
            registered = false;
        }
    }

    /**
     * Method allowing to check whether the Wi-Fi Direct adapter is enabled.
     *
     * @return true if it is enabled, otherwise false.
     */
    private boolean isWifiEnabled() {
        if (verbose) Log.d(TAG, "isWifiEnabled()");

        WifiManager wifiManager = (WifiManager) context
            .getApplicationContext()
            .getSystemService(Context.WIFI_SERVICE);

        return wifiManager != null && wifiManager.isWifiEnabled();
    }

    /**
     * Method allowing to update the device Wi-Fi adapter name.
     *
     * @param name  String value representing the new name of the device Wi-Fi 
     *              adapter.
     *
     * @return true if the name was set, otherwise false.
     */
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

    /**
     * Method allowing to reset the name of the device Wi-Fi adapter.
     */
    private boolean resetDeviceName() {
        return (initialName != null) ? updateDeviceName(initialName) : false;
    }

    /**
     * Method allowing to retrieve the MAC address of the Wi-Fi Direct adapter.
     *  
     * @return String value representing the MAC address.
     * 
     * @throws SocketException if an I/O error occurs.
     */
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

    /**
     * Method allowing to get the error message as a String according to the
     * error code integer value.
     *
     * @param reasonCode    Integer value representing the reason of failure.
     * 
     * @return String value representing the reason for failure.
     */
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

    /* 
     * Method allowing to start the discovery process of Wi-Fi Direct peers.
     */
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

    /**
     * Method allowing to connect to a remote Wi-Fi Direct peer.
     *
     * @param remoteAddress String value representing the IP address of the 
     *                      remote Wi-Fi Direct peer.
     */
    private void connect(final String remoteAddress) {
        final WifiP2pConfig config = new WifiP2pConfig();
        config.deviceAddress = remoteAddress.toLowerCase();
        config.wps.setup = WpsInfo.PBC;

        wifiP2pManager.connect(channel, config, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                if (verbose) Log.d(TAG, "connect(): success");
            }

            @Override
            public void onFailure(int reasonCode) {
                if (verbose) Log.e(TAG, "connect(): failure -> " + errorCode(reasonCode));
            }
        });
    }

    /**
     * Method allowing to remove a existing P2P group.
     */
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
