package com.montefiore.thaidinhle.adhoclibrary.ble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.util.Log;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.EventChannel.EventSink;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.UUID;

public class GattServerManager {
    private static final String TAG = "[AdHocPlugin][GattServer]";
    private static final String STREAM = "ad.hoc.lib/plugin.ble.stream";

    private final BluetoothGattServer gattServer;
    private final EventChannel eventStream;

    private EventSink eventSink;
    private HashMap<String, ArrayList<byte[]>> data;
    private HashMap<String, Integer> mtus;

    public GattServerManager(BluetoothManager bluetoothManager, Context context, BinaryMessenger messenger) {
        this.gattServer = bluetoothManager.openGattServer(context, bluetoothGattServerCallback);
        this.data = new HashMap<>();
        this.bleEventStream = new EventChannel(messenger, STREAM);
        this.bleEventStream.setStreamHandler(initStreamHandler());
    }

    private StreamHandler initStreamHandler() {
        return new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                Log.d(TAG, "onListen()");
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                Log.d(TAG, "onCancel()");
                closeGattServer();
            }
        };
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
            Log.d(TAG, Integer.toString(value.length));
            Log.d(TAG, "onCharacteristicWriteRequest()");
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, 
                                               responseNeeded, offset, value);
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value);
            processData(device, value);
        }

        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            Log.d(TAG, "onConnectionStateChange()");
            super.onConnectionStateChange(device, status, newState);
        }

        @Override
        public void onMtuChanged(BluetoothDevice device, int mtu) {
            Log.d(TAG, "onMtuChanged()");
            super.onMtuChanged(device, mtu);
            mtus.put(address, mtu);
        }
    };

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

    public void closeGattServer() {
        gattServer.close();
        eventStream.setStreamHandler(null);
    }

    private void processData(BluetoothDevice device, byte[] value) {
        ArrayList<byte[]> received;
        String address = device.getAddress();
        if (data.containsKey(address)) {
            received = data.get(address);
        } else {
            received = new ArrayList<>();
            mtus.put(address, BluetoothUtils.DEFAULT_MTU);
        }

        received.add(value);
        data.put(address, received);

        if (value[0] == BluetoothUtils.END_MESSAGE) {
            eventSink.success(data.get(address));
            data.put(address, new ArrayList<>());
        }
    }
}
