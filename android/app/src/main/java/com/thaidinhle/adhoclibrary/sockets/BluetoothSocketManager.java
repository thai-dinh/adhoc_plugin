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

public class BluetoothSocketManager {
    private static final String BLUETOOTH_UUID = "e0917680-d427-11e4-8830-";
    private static final String TAG = "[AdHoc][Blue.Socket.Manager]";

    private final BluetoothAdapter bluetoothAdapter;

    private HashMap<String, BluetoothSocket> bluetoothSockets;

    public BluetoothSocketManager() {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.bluetoothSockets = new HashMap<>();
    }

    public void connect(String macAddress, boolean secure) throws NoConnectionException {
        Log.d(TAG, "connection");
        BluetoothDevice remoteDevice = 
            bluetoothAdapter.getRemoteDevice(macAddress);
        BluetoothSocket socket;
        String uuidString = BLUETOOTH_UUID + macAddress.replace(":", "").toLowerCase();
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
            throw new NoConnectionException("Unable to connect to " + uuidString);
        }

        bluetoothSockets.put(macAddress, socket);
    }

    public void close(String macAddress) throws IOException{
        bluetoothSockets.get(macAddress).getInputStream().close();
        bluetoothSockets.get(macAddress).getOutputStream().close();
        bluetoothSockets.get(macAddress).close();
    }

    public void sendMessage(String macAddress, MessageAdHoc message) throws IOException {
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
