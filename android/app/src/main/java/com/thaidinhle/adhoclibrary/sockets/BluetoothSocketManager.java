import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;

import java.util.HashMap;

public class BluetoothSocketManager {
    private final BluetoothAdapter bluetoothAdapter;

    private HashMap<String, BluetoothSocket> bluetoothSockets;

    public BluetoothSockerManager() {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.bluetoothSockets = new HashMap<>();
    }

    public void createSocket(String macAddress, boolean secure) {
        BluetoothDevice remoteDevice = 
            bluetoothAdapter.getRemoteDevice(macAddress);
        BluetoothSocket socket;

        if (secure) { // %TODO: UUID to integrate + try/catch
            socket = remoteDevice.createRfcommSocketToServiceRecord();
        } else {
            socket = remoteDevice.createInsecureRfcommSocketToServiceRecord();
        }

        sockets[macAddress] = socket;
    }

    public void close(String macAddress) {
        sockets[macAddress].close();
    }

    // %TODO: implement MessageAdHoc class
    public void outputStream(String macAddress, MessageAdHoc message) {
        // Serialize message
    }

    // %TODO: to finish
    public MessageAdHoc inputStream(String macAddress) {
        return null;
    }
}
