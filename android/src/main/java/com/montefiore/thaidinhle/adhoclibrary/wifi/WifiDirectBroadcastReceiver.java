package com.montefiore.thaidinhle.adhoclibrary.wifi;

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
    private static final String TAG = "[AdHoc][BroadcastReceiver]";

    private boolean verbose;
    private Channel channel;
    private HashMap<String, EventSink> mapNameEventSink;
    private WifiP2pManager wifiP2pManager;

    public WifiDirectBroadcastReceiver(
        Channel channel, HashMap<String, EventSink> mapNameEventSink, WifiP2pManager wifiP2pManager
    ) {
        this.verbose = false;
        this.channel = channel;
        this.mapNameEventSink = mapNameEventSink;
        this.wifiP2pManager = wifiP2pManager;
    }

    public void setVerbose(boolean verbose) {
        if (verbose) Log.d(TAG, "setVerbose()");
        this.verbose = verbose;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        switch (action) {
            case WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): STATE_CHANGED");
                EventSink eventSink = mapNameEventSink.get("STATE_CHANGED");
                if (eventSink == null) {
                    return;
                }
    
                int state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1);
                if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                    eventSink.success(true);
                } else {
                    eventSink.success(false);
                }
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
    
                HashMap<String, Object> mapInfoValue = new HashMap<>();
                mapInfoValue.put("name", wifiP2pDevice.deviceName);
                mapInfoValue.put("mac", wifiP2pDevice.deviceAddress.toUpperCase());
    
                EventSink eventSink = mapNameEventSink.get("THIS_DEVICE_CHANGED");
                if (eventSink == null) {
                    return;
                }
    
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

            List<WifiP2pDevice> refreshedPeers = new ArrayList<>(peerList.getDeviceList());
            List<HashMap<String, Object>> listPeers = new ArrayList<>();
            for (WifiP2pDevice wifiP2pDevice : refreshedPeers) {
                HashMap<String, Object> mapInfoValue = new HashMap<>();
                mapInfoValue.put("name", wifiP2pDevice.deviceName);
                mapInfoValue.put("mac", wifiP2pDevice.deviceAddress.toUpperCase());
                listPeers.add(mapInfoValue);
            }

            EventSink eventSink = mapNameEventSink.get("PEERS_CHANGED");
            if (eventSink == null) {
                return;
            }

            eventSink.success(listPeers);
        }
    };

    private WifiP2pManager.ConnectionInfoListener connectionInfoListener = new WifiP2pManager.ConnectionInfoListener() {
        @Override
        public void onConnectionInfoAvailable(final WifiP2pInfo info) {
            if (verbose) Log.d(TAG, "onConnectionInfoAvailable");

            HashMap<String, Object> mapInfoValue = new HashMap<>();
            EventSink eventSink = mapNameEventSink.get("CONNECTION_CHANGED");
            if (eventSink == null) {
                return;
            }

            mapInfoValue.put("groupFormed", info.groupFormed);
            mapInfoValue.put("isGroupOwner", info.isGroupOwner);
            if (info.groupFormed) {
                mapInfoValue.put("groupOwnerAddress", info.groupOwnerAddress.getHostAddress());
            } else {
                mapInfoValue.put("groupOwnerAddress", "null");
            }

            eventSink.success(mapInfoValue);
        }
    };
}
