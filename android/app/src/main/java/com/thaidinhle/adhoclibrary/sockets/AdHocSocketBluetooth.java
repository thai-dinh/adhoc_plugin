package com.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothSocket;

public class AdHocSocketBluetooth {
    private BluetoothSocket socket;

    public AdHocSocketBluetooth(BluetoothSocket socket) {
        this.socket = socket;
    }

    public String getRemoteSocketAddress() {
        return socket.getRemoteDevice().getAddress();
    }

    public void close() throws IOException {
        socket.close();
    }

    public OutputStream getOutputStream() throws IOException {
        return socket.getOutputStream();
    }

    public InputStream getInputStream() throws IOException {
        return socket.getInputStream();
    }
}
