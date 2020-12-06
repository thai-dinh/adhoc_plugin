package com.montefiore.thaidinhle.adhoclibrary.wifi;

import android.content.Context;
import android.content.IntentFilter;
import android.net.wifi.p2p.WifiP2pConfig;
import android.net.wifi.p2p.WifiP2pDevice;
import android.net.wifi.p2p.WifiP2pDeviceList;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.WpsInfo;
import android.util.Log;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.exceptions.DeviceException;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static android.net.wifi.p2p.WifiP2pManager.BUSY;
import static android.net.wifi.p2p.WifiP2pManager.ERROR;
import static android.net.wifi.p2p.WifiP2pManager.P2P_UNSUPPORTED;
import static android.os.Looper.getMainLooper;

public class WifiAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHocPlugin][WifiManager]";
    private static final String STREAM = "ad.hoc.lib/plugin.wifi.stream";

    public static final int DISCOVERY_TIME = 10000;

    private final EventChannel bleEventStream;

    private Context context;
    private Channel channel;
    private EventSink eventSink;
    private WifiP2pManager wifiP2pManager;
    private HashMap<String, WifiP2pDevice> mapMacDevices;
    private WifiDirectBroadcastDiscovery wifiDirectBroadcastDiscovery;

    private boolean discoveryRegistered = false;
    private int valueGroupOwner = -1;

    public WifiAdHocManager(BinaryMessenger messenger, Context context) {
        this.context = context;
        this.wifiP2pManager = (WifiP2pManager) context.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = wifiP2pManager.initialize(context, getMainLooper(), null);
        this.mapMacDevices = new HashMap<>();
        this.bleEventStream = new EventChannel(messenger, STREAM);
        this.bleEventStream.setStreamHandler(initStreamHandler());
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "startDiscovery":
                startDiscovery();
                break;
            case "stopDiscovery":
                stopDiscovery();
                break;
            case "connect":
                final String address = call.argument("address");
                try {
                    connect(address);
                } catch (DeviceException e) {
                    e.printStackTrace();
                    result.error("exception", "connection failed", null);
                }
                break;
            case "cancelConnection":
                cancelConnection();
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    private StreamHandler initStreamHandler() {
        return new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                unregisterDiscovery();
            }
        };
    }

    private String errorCode(int reasonCode) {
        switch (reasonCode) {
            case ERROR:
                return "P2P internal error";
            case P2P_UNSUPPORTED:
                return "P2P is not supported";
            case BUSY:
                return "P2P is busy";

            default:
                return "Unknown error";
        }
    }

    private void discoverPeers() {
        wifiP2pManager.discoverPeers(channel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "discoverPeers(): Success");
            }

            @Override
            public void onFailure(int reasonCode) {
                Log.e(TAG, "discoverPeers(): Failure: " + errorCode(reasonCode));
            }
        });
    }

    private void startDiscovery() {
        final IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION);

        WifiP2pManager.PeerListListener peerListListener = new WifiP2pManager.PeerListListener() {
            @Override
            public void onPeersAvailable(WifiP2pDeviceList peerList) {
                Log.d(TAG, "onPeersAvailable()");

                List<WifiP2pDevice> refreshedPeers = new ArrayList<>(peerList.getDeviceList());

                for (WifiP2pDevice wifiP2pDevice : refreshedPeers) {
                    String deviceName = wifiP2pDevice.deviceName;
                    String deviceAddress = wifiP2pDevice.deviceAddress;

                    if (!mapMacDevices.containsKey(deviceAddress)) {
                        Log.d(TAG, "Device added: " + deviceName);

                        mapMacDevices.put(deviceAddress, wifiP2pDevice);

                        Map<String, Object> device = new HashMap<>();
                        device.put("deviceName", deviceName);
                        device.put("deviceAddress", deviceAddress);
    
                        eventSink.success(device);
                    }
                }
            }
        };

        wifiDirectBroadcastDiscovery =
            new WifiDirectBroadcastDiscovery(wifiP2pManager, channel, peerListListener);

        context.registerReceiver(wifiDirectBroadcastDiscovery, intentFilter);
        discoveryRegistered = true;

        discoverPeers();
    }

    private void unregisterDiscovery() {
        if (discoveryRegistered) {
            Log.d(TAG, "unregisterDiscovery()");
            context.unregisterReceiver(wifiDirectBroadcastDiscovery);
            discoveryRegistered = false;
        }
    }

    public void stopDiscovery() {
        wifiP2pManager.stopPeerDiscovery(channel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "stopDiscovery(): Success");
            }

            @Override
            public void onFailure(int reason) {
                Log.e(TAG, "stopDiscovery(): Failure: " + errorCode(reason));
            }
        });

        if (discoveryRegistered)
            unregisterDiscovery();
    }

    private void connect(final String remoteAddress) throws DeviceException {
        final WifiP2pDevice device = (WifiP2pDevice) mapMacDevices.get(remoteAddress);
        if (device == null)
            throw new DeviceException("Discovery is required before connecting");

        final WifiP2pConfig config = new WifiP2pConfig();
        config.groupOwnerIntent = valueGroupOwner;
        config.deviceAddress = device.deviceAddress.toLowerCase();
        config.wps.setup = WpsInfo.PBC;

        wifiP2pManager.connect(channel, config, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "connect(): Success");
            }

            @Override
            public void onFailure(int reasonCode) {
                Log.e(TAG, "connect(): Failure: " + errorCode(reasonCode));
            }
        });
    }

    private void cancelConnection() {
        if (wifiP2pManager != null) {
            wifiP2pManager.cancelConnect(channel, new WifiP2pManager.ActionListener() {
                @Override
                public void onSuccess() {
                    Log.d(TAG, "cancelConnection(): Success");
                }

                @Override
                public void onFailure(int reason) {
                    Log.e(TAG, "cancelConnection(): Failure: " + errorCode(reason));
                }
            });
        }
    }
}
