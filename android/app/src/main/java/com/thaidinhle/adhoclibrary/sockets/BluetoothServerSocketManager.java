package com.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;

import java.io.IOException;
import java.util.HashMap;
import java.util.UUID;

public class BluetoothServerSocketManager {
    private static final String TAG = "[AdHoc][Blue.ServerSocket.Manager]";

    private final BluetoothAdapter bluetoothAdapter;
    
    private HashMap<String, BluetoothServerSocket> bluetoothServerSockets;

    public BluetoothServerSocketManager() {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.bluetoothServerSockets = new HashMap<>();
    }

    public void createServerSocket(String name, String uuidString, boolean secure) 
        throws IOException {

        UUID uuid = UUID.fromString(uuidString);
        BluetoothServerSocket serverSocket;

        if (secure) {
            serverSocket =  bluetoothAdapter.listenUsingRfcommWithServiceRecord(name, uuid);
        } else {
            serverSocket =  bluetoothAdapter.listenUsingInsecureRfcommWithServiceRecord(name, uuid);
        }

        bluetoothServerSockets.put(name, serverSocket);
    }

    public BluetoothSocket accept(String name) throws IOException {
        return bluetoothServerSockets.get(name).accept();
    }

    public void close(String name) throws IOException {
        bluetoothServerSockets.get(name).close();
        bluetoothServerSockets.remove(name);
    }
}
