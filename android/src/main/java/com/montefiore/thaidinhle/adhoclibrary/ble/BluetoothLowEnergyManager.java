package com.montefiore.thaidinhle.adhoclibrary.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.util.Log;

import com.montefiore.thaidinhle.adhoclibrary.ble.gatt.GattServer;

public class BluetoothLowEnergyManager {
    private static final String TAG = "[AdHoc.Plugin][BLE.Manager]";

    private final BluetoothAdapter bluetoothAdapter;
    private final BluetoothLeAdvertiser bluetoothLeAdvertiser;
    private final BluetoothManager bluetoothManager;
    private final Context context;
    private final GattServer gattServer;

    public BluetoothLowEnergyManager(Context context) {
        this.bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        this.bluetoothAdapter = bluetoothManager.getAdapter();
        this.bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
        this.context = context;
        this.gattServer = new GattServer(bluetoothManager, context);
        this.gattServer.openGattServer();
    }

    private AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure (int errorCode) {
            Log.d(TAG, "onStartFailure(): " + Integer.toString(errorCode));
            super.onStartFailure(errorCode);
        }

        @Override
        public void onStartSuccess (AdvertiseSettings settingsInEffect) {
            Log.d(TAG, "onStartSuccess()");
            super.onStartSuccess(settingsInEffect);
        }
    };

    public void startAdvertise() {
        Log.d(TAG, "startAdvertise()");

        AdvertiseData data = new AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .build();

        AdvertiseSettings settings = new AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setConnectable(true)
            .setTimeout(0) // 0 = no time limit
            .build();

        bluetoothLeAdvertiser.startAdvertising(settings, data, advertiseCallback);
    }

    public void stopAdvertise() {
        Log.d(TAG, "stopAdvertise()");
        bluetoothLeAdvertiser.stopAdvertising(advertiseCallback);
    }
}
