package com.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.util.Log;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;
import java.util.UUID;

public class BluetoothClientSocketManager {
    private static final String TAG = "[AdHoc][Blue.Socket.Manager]";

    private final BluetoothAdapter bluetoothAdapter;

    private HashMap<String, BluetoothSocket> bluetoothSockets;

    public BluetoothClientSocketManager() {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.bluetoothSockets = new HashMap<>();
    }

    public void addSocket(BluetoothSocket socket) {
        final String macAddress = socket.getRemoteDevice().getAddress();
        bluetoothSockets.put(macAddress, socket);
    }

    public boolean connect(String macAddress, boolean secure, String uuidString) {
        BluetoothDevice remoteDevice = bluetoothAdapter.getRemoteDevice(macAddress);
        BluetoothSocket socket;
        UUID uuid = UUID.fromString(uuidString);

        try {
            if (secure) {
                socket = remoteDevice.createRfcommSocketToServiceRecord(uuid);
            } else {
                socket = remoteDevice.createInsecureRfcommSocketToServiceRecord(uuid);
            }

            timeout(socket);
            socket.connect();
        } catch (IOException e) {
            return false;
        }

        bluetoothSockets.put(macAddress, socket);

        return true;
    }

    public void close(String macAddress) throws IOException {
        bluetoothSockets.get(macAddress).getInputStream().close();
        bluetoothSockets.get(macAddress).getOutputStream().close();
        bluetoothSockets.get(macAddress).close();
    }

    public void sendMessage(String macAddress, MessageAdHoc message) throws IOException {
        BluetoothSocket socket = bluetoothSockets.get(macAddress);
        if (socket == null) {
            Log.d(TAG, "Null");
            return;
        }

        OutputStream os = bluetoothSockets.get(macAddress).getOutputStream();
        DataOutputStream dos = new DataOutputStream(os);

        dos.write(42);
    }

    public int receiveMessage(String macAddress) throws IOException {
        InputStream is = bluetoothSockets.get(macAddress).getInputStream();
        DataInputStream dis = new DataInputStream(is);

        return dis.readInt();
    }

    private void timeout(BluetoothSocket socket) {
        new Timer().schedule(new TimerTask() {
            @Override
            public void run() {
                if (!socket.isConnected()) {
                    try {
                        socket.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }, 10000); // 10 seconds
    }
}
