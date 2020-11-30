package com.montefiore.thaidinhle.adhoclibrary.wifi;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.p2p.WifiP2pManager.PeerListListener;
import android.util.Log;

public class WifiDirectBroadcastDiscovery extends BroadcastReceiver {
    private static final String TAG = "[AdHocPlugin][WifiDiscovery]";
    private WifiP2pManager manager;
    private Channel channel;
    private PeerListListener peerListListener;

    public WifiDirectBroadcastDiscovery(WifiP2pManager manager, Channel channel,
                                        PeerListListener peerListListener) {
        super();

        this.manager = manager;
        this.channel = channel;
        this.peerListListener = peerListListener;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();

        if (WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION.equals(action)) {
            int state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1);
            if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                Log.d(TAG, "P2P state enabled: " + state);
            } else {
                Log.d(TAG, "P2P state disabled: " + state);
            }
        } else if (WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION.equals(action)) {
            if (manager != null)
                manager.requestPeers(channel, peerListListener);
        }
    }
}
