package com.montefiore.thaidinhle.adhoclibrary.ble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.util.Log;

import com.montefiore.thaidinhle.adhoclibrary.ble.BluetoothUtils;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.UUID;

public class GattServerManager {
    private static final String TAG = "[AdHocPlugin][GattServer]";

    private final BluetoothGattServer gattServer;

    private HashMap<String, byte[]> characteristicValues;

    public GattServerManager(BluetoothManager bluetoothManager, Context context) {
        gattServer = bluetoothManager.openGattServer(context, bluetoothGattServerCallback);
        characteristicValues = new HashMap<String, byte[]>();
    }

    private BluetoothGattServerCallback bluetoothGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onCharacteristicReadRequest(BluetoothDevice device, int requestId, int offset,
                                                BluetoothGattCharacteristic characteristic)
        {
            Log.d(TAG, "onCharacteristicReadRequest()");
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic);
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, characteristic.getValue());
        }

        @Override
        public void onCharacteristicWriteRequest(BluetoothDevice device, int requestId, 
                                                 BluetoothGattCharacteristic characteristic,
                                                 boolean preparedWrite, boolean responseNeeded,
                                                 int offset, byte[] value)
        {
            Log.d(TAG, "onCharacteristicWriteRequest()");
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, 
                                               responseNeeded, offset, value);
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value);

            String address = device.getAddress();
            Log.d(TAG, "onCharacteristicWriteRequest(): address=" + address);
            if (!characteristicValues.containsKey(address)) {
                characteristicValues.put(address, value);
            } else {
                try {
                    characteristicValues.replace(address, addValues(address, value));
                } catch (IOException error) {
                    Log.d(TAG, "onCharacteristicWriteRequest(): IOException thrown");
                }
            }
        }

        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            Log.d(TAG, "onConnectionStateChange()");
            super.onConnectionStateChange(device, status, newState);
        }
    };

    private byte[] addValues(String address, byte[] value) throws IOException {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        outputStream.write(characteristicValues.get(address));
        outputStream.write(value);
        return outputStream.toByteArray();
    }

    public void setupGattServer() {
        BluetoothGattCharacteristic characteristic =
            new BluetoothGattCharacteristic(UUID.fromString(BluetoothUtils.CHARACTERISTIC_UUID),
                                            BluetoothGattCharacteristic.PROPERTY_READ |
                                            BluetoothGattCharacteristic.PROPERTY_WRITE |
                                            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                                            BluetoothGattCharacteristic.PERMISSION_READ |
                                            BluetoothGattCharacteristic.PERMISSION_WRITE);

        BluetoothGattService service =
            new BluetoothGattService(UUID.fromString(BluetoothUtils.SERVICE_UUID),
                                     BluetoothGattService.SERVICE_TYPE_PRIMARY);
        service.addCharacteristic(characteristic);

        gattServer.addService(service);
    }

    public HashMap<String, byte[]> getValues() {
        return characteristicValues;
    }

    public void closeGattServer() {
        gattServer.close();
    }
}
