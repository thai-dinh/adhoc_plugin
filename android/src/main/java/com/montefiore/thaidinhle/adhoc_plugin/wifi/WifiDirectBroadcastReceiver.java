package com.montefiore.thaidinhle.adhoc_plugin.wifi;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.ConnectivityManager.NetworkCallback;
import android.net.Network;
import android.net.wifi.WifiManager;
import android.net.wifi.p2p.WifiP2pDevice;
import android.net.wifi.p2p.WifiP2pDeviceList;
import android.net.wifi.p2p.WifiP2pInfo;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.p2p.WifiP2pManager.PeerListListener;
import android.util.Log;

import io.flutter.plugin.common.EventChannel.EventSink;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;


public class WifiDirectBroadcastReceiver extends BroadcastReceiver {
    private static final String TAG = "[AdhocPlugin][BroadcastReceiver]";

    private boolean verbose;
    private Channel channel;
    private EventSink eventSink;
    private WifiP2pManager wifiP2pManager;

    public WifiDirectBroadcastReceiver(
        Channel channel, EventSink eventSink, WifiP2pManager wifiP2pManager
    ) {
        this.verbose = false;
        this.channel = channel;
        this.eventSink = eventSink;
        this.wifiP2pManager = wifiP2pManager;
    }

    public void setVerbose(boolean verbose) {
        if (verbose) Log.d(TAG, "setVerbose()");
        this.verbose = verbose;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        HashMap<String, Object> mapInfoValue = new HashMap<>();
        String action = intent.getAction();

        switch (action) {
            case WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): STATE_CHANGED");
    
                int state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1);
                mapInfoValue.put("type", 121);
                if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                    mapInfoValue.put("state", true);
                } else {
                    mapInfoValue.put("state", false);
                }

                eventSink.success(mapInfoValue);
                break;
            }

            case WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): PEERS_CHANGED");
                if (wifiP2pManager != null) {
                    wifiP2pManager.requestPeers(channel, peerListListener);
                }
                break;
            }

            case WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): CONNECTION_CHANGED");
                wifiP2pManager.requestConnectionInfo(channel, connectionInfoListener);
                break;
            }

            case WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): THIS_DEVICE_CHANGED");
                WifiP2pDevice wifiP2pDevice = 
                    (WifiP2pDevice) intent.getParcelableExtra(WifiP2pManager.EXTRA_WIFI_P2P_DEVICE);
                
                mapInfoValue.put("type", 123);
                mapInfoValue.put("name", wifiP2pDevice.deviceName);
                mapInfoValue.put("mac", wifiP2pDevice.deviceAddress.toUpperCase());
    
                eventSink.success(mapInfoValue);
                break;
            }

            default:
                break;
        }
    }

    private PeerListListener peerListListener = new PeerListListener() {
        @Override
        public void onPeersAvailable(WifiP2pDeviceList peerList) {
            if (verbose) Log.d(TAG, "onPeersAvailable()");
            
            HashMap<String, Object> mapInfoValue = new HashMap<>();
            mapInfoValue.put("type", 120);

            List<WifiP2pDevice> refreshedPeers = new ArrayList<>(peerList.getDeviceList());
            List<HashMap<String, Object>> listPeers = new ArrayList<>();
            for (WifiP2pDevice wifiP2pDevice : refreshedPeers) {
                HashMap<String, Object> mapDeviceInfoValue = new HashMap<>();
                mapDeviceInfoValue.put("name", wifiP2pDevice.deviceName);
                mapDeviceInfoValue.put("mac", wifiP2pDevice.deviceAddress.toUpperCase());
                listPeers.add(mapDeviceInfoValue);
            }

            mapInfoValue.put("peers", listPeers);

            eventSink.success(mapInfoValue);
        }
    };

    private WifiP2pManager.ConnectionInfoListener connectionInfoListener = new WifiP2pManager.ConnectionInfoListener() {
        @Override
        public void onConnectionInfoAvailable(final WifiP2pInfo info) {
            if (verbose) Log.d(TAG, "onConnectionInfoAvailable()");

            HashMap<String, Object> mapInfoValue = new HashMap<>();
            HashMap<String, Object> mapConnectionInfoValue = new HashMap<>();
            mapInfoValue.put("type", 122);
            
            
            mapConnectionInfoValue.put("groupFormed", info.groupFormed);
            mapConnectionInfoValue.put("isGroupOwner", info.isGroupOwner);

            if (info.groupFormed) {
                mapConnectionInfoValue.put("groupOwnerAddress", info.groupOwnerAddress.getHostAddress());
            } else {
                mapConnectionInfoValue.put("groupOwnerAddress", "");
            }

            mapInfoValue.put("info", mapConnectionInfoValue);

            eventSink.success(mapInfoValue);
        }
    };
}
