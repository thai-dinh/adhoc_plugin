package com.montefiore.thaidinhle.adhoclibrary.ble.gatt;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.content.Context;

import java.util.UUID;

public class GattServer {
    private static final String SERVICE_UUID = "0000AD00-0000-0000-0000-000000000000";
    private static final String CHARACTERISTIC_UUID = "0000AD01-0000-0000-0000-000000000002";
    private static final String DESCRIPTOR_UUID = "0000D301-0000-0000-0000-000000000003";

    private final BluetoothGattServer gattServer;

    public GattServer(BluetoothManager bluetoothManager, Context context) {
        gattServer = bluetoothManager.openGattServer(context, bluetoothGattServerCallback);
    }

    private BluetoothGattServerCallback bluetoothGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onCharacteristicReadRequest(BluetoothDevice device, int requestId, int offset,
                                                BluetoothGattCharacteristic characteristic)
        {
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic);
        }

        @Override
        public void onCharacteristicWriteRequest(BluetoothDevice device, int requestId, 
                                                 BluetoothGattCharacteristic characteristic,
                                                 boolean preparedWrite, boolean responseNeeded,
                                                 int offset, byte[] value)
        {
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, 
                                               responseNeeded, offset, value);
        }

        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            super.onConnectionStateChange(device, status, newState);
        }

        @Override
        public void onDescriptorReadRequest(BluetoothDevice device, int requestId, int offset,
                                            BluetoothGattDescriptor descriptor)
        {
            super.onDescriptorReadRequest(device, requestId, offset, descriptor);
        }

        @Override
        public void onDescriptorWriteRequest(BluetoothDevice device, int requestId, 
                                             BluetoothGattDescriptor descriptor, 
                                             boolean preparedWrite, boolean responseNeeded, 
                                             int offset, byte[] value)
        {
            super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite,
                                           responseNeeded, offset, value);
        }
    };

    public void openGattServer() {
        byte[] value = {1, 2, 3, 4, 5};
        BluetoothGattDescriptor descriptor =
            new BluetoothGattDescriptor(UUID.fromString(DESCRIPTOR_UUID),
                                        BluetoothGattCharacteristic.PERMISSION_WRITE);
        descriptor.setValue(value);

        BluetoothGattCharacteristic characteristic =
            new BluetoothGattCharacteristic(UUID.fromString(CHARACTERISTIC_UUID),
                                            BluetoothGattCharacteristic.PROPERTY_READ |
                                            BluetoothGattCharacteristic.PROPERTY_WRITE |
                                            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                                            BluetoothGattCharacteristic.PERMISSION_READ |
                                            BluetoothGattCharacteristic.PERMISSION_WRITE);
        characteristic.addDescriptor(descriptor);
        
        BluetoothGattService service =
            new BluetoothGattService(UUID.fromString(SERVICE_UUID),
                                     BluetoothGattService.SERVICE_TYPE_PRIMARY);
        service.addCharacteristic(characteristic);

        gattServer.addService(service);
    }
}
