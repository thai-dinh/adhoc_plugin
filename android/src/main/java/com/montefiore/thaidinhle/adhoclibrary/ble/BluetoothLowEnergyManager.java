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
    }

    private AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure (int errorCode) {
            super.onStartFailure(errorCode);
            Log.d(TAG, "onStartFailure(): " + Integer.toString(errorCode));
        }

        @Override
        public void onStartSuccess (AdvertiseSettings settingsInEffect) {
            super.onStartSuccess(settingsInEffect);
            Log.d(TAG, "onStartSuccess()");
        }
    };

    public void startAdvertise() {
        AdvertiseData.Builder data = new AdvertiseData.Builder();
        data.setIncludeDeviceName(true);

        AdvertiseSettings.Builder settings = new AdvertiseSettings.Builder();
        settings.setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_POWER);
        settings.setConnectable(true); // Allow remote connections to the device
        settings.setTimeout(0); // 0 = not time limit

        bluetoothLeAdvertiser.startAdvertising(settings.build(), data.build(), advertiseCallback);
    }

    public void stopAdvertise() {
        bluetoothLeAdvertiser.stopAdvertising(advertiseCallback);
    }
}
