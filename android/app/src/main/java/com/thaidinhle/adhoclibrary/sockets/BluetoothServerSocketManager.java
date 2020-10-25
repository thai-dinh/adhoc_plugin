package com.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;

import java.io.IOException;
import java.util.UUID;

public class BluetoothServerSocketManager {
    private final BluetoothAdapter bluetoothAdapter;
    
    private BluetoothServerSocket serverSocket;

    public BluetoothServerSocketManager() {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    }

    public void createServerSocket(String name, String uuidString, boolean secure) throws IOException {
        UUID uuid = UUID.fromString(uuidString);

        if (secure) {
            serverSocket =  bluetoothAdapter.listenUsingRfcommWithServiceRecord(name, uuid);
        } else {
            serverSocket =  bluetoothAdapter.listenUsingInsecureRfcommWithServiceRecord(name, uuid);
        }
    }

    public BluetoothSocket accept() throws IOException {
        return serverSocket.accept();
    }

    public void close() throws IOException {
        serverSocket.close();
    }
}
