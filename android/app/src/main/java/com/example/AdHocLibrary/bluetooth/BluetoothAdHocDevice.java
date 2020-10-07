package com.example.AdHocLibrary.bluetooth;

public class BluetoothAdHocDevice {
    private final String deviceName;
    private final String macAddress;
    private final int rssi;

    public BluetoothAdHocDevice(String deviceName, String macAddress) {
        this.deviceName = deviceName;
        this.macAddress = macAddress;
        this.rssi = -1;
    }

    public BluetoothAdHocDevice(String deviceName, String macAddress, int rssi) {
        this.deviceName = deviceName;
        this.macAddress = macAddress;
        this.rssi = rssi;
    }

    public String getName() {
        return deviceName;
    }

    public String getAddress() {
        return macAddress;
    }

    public int getRssi() {
        return rssi;
    }
}
