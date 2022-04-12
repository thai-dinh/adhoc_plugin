package com.montefiore.thaidinhle.adhoc_plugin.wifi;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
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


/** 
 * Class defining a BroadcastReceiver that notifies of Wi-Fi Direct events.
 */
public class WifiBroadcastReceiver extends BroadcastReceiver {
    private static final String TAG = "[AdHocPlugin][BR]";

    // Constants for communication with the Flutter platform barrier
    private static final byte ANDROID_DISCOVERY  = 120;
    private static final byte ANDROID_STATE      = 121;
    private static final byte ANDROID_CONNECTION = 122;
    private static final byte ANDROID_CHANGES    = 123;

    private boolean verbose;
    private final Channel channel;
    private final EventSink eventSink;
    private final WifiP2pManager wifiP2pManager;

    /**
     * Default constructor
     * 
     * @param channel           Wi-Fi Direct channel representing the channel 
     *                          connecting the application to the Wi-Fi Direct 
     *                          framework.
     * @param eventSink         Event callback for sending event to the Flutter
     *                          client.
     * @param wifiP2pManager    Class managing Wi-Fi Direct connectivity.
    */
    public WifiBroadcastReceiver(
        Channel channel, EventSink eventSink, WifiP2pManager wifiP2pManager
    ) {
        this.verbose = false;
        this.channel = channel;
        this.eventSink = eventSink;
        this.wifiP2pManager = wifiP2pManager;
    }

    /** 
     * Method allowing to update the verbose/debug mode.
     * 
     * @param verbose   Boolean value representing the sate of the verbose/debug 
     *                  mode.
     */
    public void setVerbose(boolean verbose) {
        this.verbose = verbose;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        HashMap<String, Object> mapInfoValue = new HashMap<>();
        String action = intent.getAction();

        switch (action) {
            case WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): STATE_CHANGED");
    
                // State of Wi-Fi P2P has change
                int state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1);
                mapInfoValue.put("type", ANDROID_STATE);
                if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                    mapInfoValue.put("state", true);
                } else {
                    mapInfoValue.put("state", false);
                }
                
                // Notify Flutter client
                eventSink.success(mapInfoValue);
                break;
            }

            case WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): PEERS_CHANGED");
                // List of peer available
                if (wifiP2pManager != null) {
                    wifiP2pManager.requestPeers(channel, peerListListener);
                }
                break;
            }

            case WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): CONNECTION_CHANGED");
                // Connection established
                wifiP2pManager.requestConnectionInfo(channel, connectionInfoListener);
                break;
            }

            case WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION: {
                if (verbose) Log.d(TAG, "onReceive(): THIS_DEVICE_CHANGED");
                // Device information changed
                WifiP2pDevice wifiP2pDevice =
                        intent.getParcelableExtra(WifiP2pManager.EXTRA_WIFI_P2P_DEVICE);
                
                mapInfoValue.put("type", ANDROID_CHANGES);
                mapInfoValue.put("name", wifiP2pDevice.deviceName);
                mapInfoValue.put("mac", wifiP2pDevice.deviceAddress.toUpperCase());
    
                // Notify Flutter client
                eventSink.success(mapInfoValue);
                break;
            }

            default:
                break;
        }
    }

    // Interface for callback invocation when the peer list is available
    private final PeerListListener peerListListener = new PeerListListener() {
        @Override
        public void onPeersAvailable(WifiP2pDeviceList peerList) {
            if (verbose) Log.d(TAG, "onPeersAvailable()");
            // List of peer information available
            HashMap<String, Object> mapInfoValue = new HashMap<>();
            mapInfoValue.put("type", ANDROID_DISCOVERY);

            List<WifiP2pDevice> refreshedPeers = new ArrayList<>(peerList.getDeviceList());
            List<HashMap<String, Object>> listPeers = new ArrayList<>();
            for (WifiP2pDevice wifiP2pDevice : refreshedPeers) {
                HashMap<String, Object> mapDeviceInfoValue = new HashMap<>();
                mapDeviceInfoValue.put("name", wifiP2pDevice.deviceName);
                mapDeviceInfoValue.put("mac", wifiP2pDevice.deviceAddress.toUpperCase());
                listPeers.add(mapDeviceInfoValue);
            }

            mapInfoValue.put("peers", listPeers);
            // Notify Flutter client
            eventSink.success(mapInfoValue);
        }
    };

    // Interface for callback invocation when the connection info is available
    private final WifiP2pManager.ConnectionInfoListener connectionInfoListener = new WifiP2pManager.ConnectionInfoListener() {
        @Override
        public void onConnectionInfoAvailable(final WifiP2pInfo info) {
            if (verbose) Log.d(TAG, "onConnectionInfoAvailable()");
            // Information about the P2P group available
            HashMap<String, Object> mapInfoValue = new HashMap<>();
            HashMap<String, Object> mapConnectionInfoValue = new HashMap<>();
            mapInfoValue.put("type", ANDROID_CONNECTION);
            
            
            mapConnectionInfoValue.put("groupFormed", info.groupFormed);
            mapConnectionInfoValue.put("isGroupOwner", info.isGroupOwner);

            if (info.groupFormed) {
                mapConnectionInfoValue.put("groupOwnerAddress", info.groupOwnerAddress.getHostAddress());
            } else {
                mapConnectionInfoValue.put("groupOwnerAddress", "");
            }

            mapInfoValue.put("info", mapConnectionInfoValue);
            // Notify Flutter client
            eventSink.success(mapInfoValue);
        }
    };
}
