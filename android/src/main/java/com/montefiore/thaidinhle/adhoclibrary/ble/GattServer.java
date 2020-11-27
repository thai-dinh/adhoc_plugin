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

import java.util.UUID;

public class GattServer {
    private static final String TAG = "[AdHoc.Plugin][Gatt.Server]";

    public static final String SERVICE_UUID = "00000001-0000-1000-8000-00805f9b34fb";
    public static final String CHARACTERISTIC_UUID = "00000002-0000-1000-8000-00805f9b34fb";

    private final BluetoothGattServer gattServer;

    public GattServer(BluetoothManager bluetoothManager, Context context) {
        gattServer = bluetoothManager.openGattServer(context, bluetoothGattServerCallback);
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
            characteristic.setValue(value);
        }

        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            Log.d(TAG, "onConnectionStateChange()");
            super.onConnectionStateChange(device, status, newState);
        }

        @Override
        public void onDescriptorReadRequest(BluetoothDevice device, int requestId, int offset,
                                            BluetoothGattDescriptor descriptor)
        {
            Log.d(TAG, "onDescriptorReadRequest()");
            super.onDescriptorReadRequest(device, requestId, offset, descriptor);
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, descriptor.getValue());
        }

        @Override
        public void onDescriptorWriteRequest(BluetoothDevice device, int requestId, 
                                             BluetoothGattDescriptor descriptor, 
                                             boolean preparedWrite, boolean responseNeeded, 
                                             int offset, byte[] value)
        {
            Log.d(TAG, "onDescriptorWriteRequest()");
            super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, 
                                           responseNeeded, offset, value);
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value);
        }
    };

    public void openGattServer() {
        BluetoothGattCharacteristic characteristic =
            new BluetoothGattCharacteristic(UUID.fromString(CHARACTERISTIC_UUID),
                                            BluetoothGattCharacteristic.PROPERTY_READ |
                                            BluetoothGattCharacteristic.PROPERTY_WRITE |
                                            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                                            BluetoothGattCharacteristic.PERMISSION_READ |
                                            BluetoothGattCharacteristic.PERMISSION_WRITE);

        BluetoothGattService service =
            new BluetoothGattService(UUID.fromString(SERVICE_UUID),
                                     BluetoothGattService.SERVICE_TYPE_PRIMARY);
        service.addCharacteristic(characteristic);

        gattServer.addService(service);
    }
}
