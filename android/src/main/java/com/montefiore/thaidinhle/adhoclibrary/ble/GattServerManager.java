package com.montefiore.thaidinhle.adhoclibrary.ble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.UUID;

public class GattServerManager {
    private static final String TAG = "[AdHocPlugin][GattServer]";
    private static final String STREAM_CONNECTION = "ad.hoc.lib/ble.connection";
    private static final String STREAM_MESSAGE = "ad.hoc.lib/ble.message";

    private BluetoothGattServer gattServer;
    private EventChannel eventConnectionChannel;
    private EventChannel eventMessageChannel;
    private HashMap<String, ArrayList<byte[]>> data;
    private HashMap<String, Integer> mtus;
    private MainThreadEventSink eventConnectionSink;
    private MainThreadEventSink eventMessageSink;
    
    public GattServerManager() {
        this.data = new HashMap<>();
        this.mtus = new HashMap<>();
    }

    public void initEventConnectionChannel(BinaryMessenger messenger) {
        eventConnectionChannel = new EventChannel(messenger, STREAM_CONNECTION);
        eventConnectionChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                Log.d(TAG, "Connection: onListen()");
                eventConnectionSink = new MainThreadEventSink(events);
            }

            @Override
            public void onCancel(Object arguments) {
                Log.d(TAG, "Connection: onCancel()");
                closeGattServer();
            }
        });
    }

    public void initEventMessageChannel(BinaryMessenger messenger) {
        eventMessageChannel = new EventChannel(messenger, STREAM_MESSAGE);
        eventMessageChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                Log.d(TAG, "Message: onListen()");
                eventMessageSink = new MainThreadEventSink(events);
            }

            @Override
            public void onCancel(Object arguments) {
                Log.d(TAG, "Message: onCancel()");
                closeGattServer();
            }
        });
    }

    public void openGattServer(BluetoothManager bluetoothManager, Context context) {
        gattServer = bluetoothManager.openGattServer(context, bluetoothGattServerCallback);

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
            Log.d(TAG, "onCharacteristicWriteRequest(): " + Byte.toString(value[0]));
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, 
                                               responseNeeded, offset, value);
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value);

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
                HashMap<String, Object> mapDeviceData = new HashMap<>();
                mapDeviceData.put("macAddress", address);
                mapDeviceData.put("values", data.get(address));
    
                eventMessageSink.success(mapDeviceData);
    
                received = new ArrayList<>();
                data.put(address, received);
            }
        }

        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            Log.d(TAG, "onConnectionStateChange()");
            super.onConnectionStateChange(device, status, newState);

            HashMap<String, Object> mapDeviceInfo = new HashMap<>();
            mapDeviceInfo.put("deviceName", device.getName());
            mapDeviceInfo.put("macAddress", device.getAddress());

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                mapDeviceInfo.put("state", BluetoothUtils.STATE_CONNECTED);
            } else {
                mapDeviceInfo.put("state", BluetoothUtils.STATE_DISCONNECTED);
            }

            eventConnectionSink.success(mapDeviceInfo);
        }

        @Override
        public void onMtuChanged(BluetoothDevice device, int mtu) {
            Log.d(TAG, "onMtuChanged()");
            super.onMtuChanged(device, mtu);
            mtus.put(device.getAddress(), mtu);
        }
    };

    public void closeGattServer() {
        gattServer.close();
        eventConnectionSink = null;
        eventMessageSink = null;
        eventConnectionChannel.setStreamHandler(null);
        eventMessageChannel.setStreamHandler(null);
    }

    // Methods marked with @UiThread must be executed on the main thread
    private static class MainThreadEventSink implements EventSink {
        private EventSink eventSink;
        private Handler handler;

        public MainThreadEventSink(EventSink eventSink) {
          this.eventSink = eventSink;
          handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object event) {
          handler.post(new Runnable() {
            @Override
            public void run() {
              eventSink.success(event);
            }
          });
        }

        @Override
        public void error(final String errorCode, final String errorMessage, final Object errorDetails) {
          handler.post(new Runnable() {
            @Override
            public void run() {
              eventSink.error(errorCode, errorMessage, errorDetails);
            }
          });
        }

        @Override
        public void endOfStream() {
            eventSink.endOfStream();
        }
    }
}
