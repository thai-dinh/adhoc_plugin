package com.montefiore.thaidinhle.adhoc_plugin.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.os.ParcelUuid;
import android.util.Log;

import java.util.UUID;

/**
 * Class managing the peripheral role in Bluetooth Low Energy.
 */
public class BleManager {
    private static final String TAG = "[AdHocPlugin][Ble]";

    private final BluetoothAdapter bluetoothAdapter;

    private BluetoothLeAdvertiser bluetoothLeAdvertiser;
    private boolean verbose;
    private final String initialName;

    /**
     * Default constructor
     */
    public BleManager() {
        this.verbose = false;
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
        this.initialName = bluetoothAdapter.getName();
    }

    // Interface callback for notification about the discovery mode (advertisement)
    private final AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure (int errorCode) {
            if (verbose) 
                Log.d(TAG, "Start advertise failure: " + errorCode);
            super.onStartFailure(errorCode);
        }

        @Override
        public void onStartSuccess (AdvertiseSettings settingsInEffect) {
            if (verbose) 
                Log.d(TAG, "Start advertise success");
            super.onStartSuccess(settingsInEffect);
        }
    };

    /**
     * Method allowing to start the advertisement process (discovery mode enable).
     */
    public void startAdvertise() {
        if (verbose) Log.d(TAG, "startAdvertise()");

        // Building the advertisement packet
        AdvertiseData data = new AdvertiseData.Builder()
            .addServiceUuid(new ParcelUuid(UUID.fromString(BleUtils.SERVICE_UUID)))
            .setIncludeDeviceName(true)
            .build();

        AdvertiseSettings settings = new AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setConnectable(true)
            .setTimeout(0) // 0 = no time limit
            .build();

        if (bluetoothLeAdvertiser == null) {
            bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
            if (bluetoothLeAdvertiser == null)
                return;
        }
    
        // Start advertisement
        bluetoothLeAdvertiser.startAdvertising(settings, data, advertiseCallback);
    }

    /**
     * Method allowing to stop the advertisement process.
     */
    public void stopAdvertise() {
        if (verbose) Log.d(TAG, "stopAdvertise()");

        if (bluetoothLeAdvertiser != null)
            bluetoothLeAdvertiser.stopAdvertising(advertiseCallback);
    }

    /** 
     * Method allowing to update the verbose/debug mode.
     * 
     * @param verbose   Boolean value representing the sate of the verbose/debug 
     *                  mode.
     */
    public void setVerbose(boolean verbose) {
        this.verbose = verbose;
    }

    /**
     * Method allowing to reset the name of the device Wi-Fi adapter.
     * 
     * @return true if it has been reset, otherwise false.
     */
    public boolean resetDeviceName() {
        if (initialName != null)
            return bluetoothAdapter.setName(initialName);
        return false;
    }

    /**
     * Method allowing to update the device Wi-Fi adapter name.
     *
     * @param name  String value representing the new name of the device Wi-Fi 
     *              adapter.
     *
     * @return true if the name was set, otherwise false.
     */
    public boolean updateDeviceName(String name) {
        return bluetoothAdapter.setName(name);
    }

    /**
     * Method allowing to get the Bluetooth adapter name.
     * 
     * @return String value representing the name of the adapter.
     */
    public String getAdapterName() {
        return bluetoothAdapter.getName();
    }

    /**
     * Method allowing to enable the Bluetooth adapter.
     * 
     * @return true if it has been enabled, otherwise false.
     */
    public boolean enable() {
        return bluetoothAdapter.enable();
    }

    /**
     * Method allowing to disable the Bluetooth adapter.
     * 
     * @return true if it has been disable, otherwise false.
     */
    public boolean disable() {
        return bluetoothAdapter.disable();
    }
}
