package com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy;

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

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import java.util.Map;

public class GattServerManager {
    private static final String TAG = "[AdHocPlugin][GattServer]";
    private static final String STREAM_CONNECTION = "ad.hoc.lib/ble.connection";
    private static final String STREAM_MESSAGE = "ad.hoc.lib/ble.message";

    private boolean verbose;
    private BluetoothGattCharacteristic characteristic;
    private BluetoothGattServer gattServer;
    private BluetoothManager bluetoothManager;
    private HashMap<String, ArrayList<byte[]>> data;
    private HashMap<String, String> mapUlidMac;
    private HashMap<String, BluetoothDevice> mapMacDevice;
    private EventChannel eventConnectionChannel;
    private EventChannel eventMessageChannel;
    private MainThreadEventSink eventConnectionSink;
    private MainThreadEventSink eventMessageSink;

    public GattServerManager() {
        this.verbose = false;
        this.data = new HashMap<>();
        this.mapUlidMac = new HashMap<>();
        this.mapMacDevice = new HashMap<>();
    }

    public void initEventChannels(BinaryMessenger messenger) {
        if (verbose) Log.d(TAG, "initEventChannels()");

        // eventConnectionChannel
        eventConnectionChannel = new EventChannel(messenger, STREAM_CONNECTION);
        eventConnectionChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                if (verbose) Log.d(TAG, "Connection: onListen()");
                eventConnectionSink = new MainThreadEventSink(events);
            }

            @Override
            public void onCancel(Object arguments) {
                if (verbose) Log.d(TAG, "Connection: onCancel()");
                eventConnectionSink = null;
                eventConnectionChannel.setStreamHandler(null);
            }
        });

        // eventMessageChannel
        eventMessageChannel = new EventChannel(messenger, STREAM_MESSAGE);
        eventMessageChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                if (verbose) Log.d(TAG, "Message: onListen()");
                eventMessageSink = new MainThreadEventSink(events);
            }

            @Override
            public void onCancel(Object arguments) {
                if (verbose) Log.d(TAG, "Message: onCancel()");
                eventMessageSink = null;
                eventMessageChannel.setStreamHandler(null);
            }
        });
    }

    public void openGattServer(BluetoothManager bluetoothManager, Context context) {
        if (verbose) Log.d(TAG, "openGattServer()");

        this.bluetoothManager = bluetoothManager;
        gattServer = bluetoothManager.openGattServer(context, bluetoothGattServerCallback);

        characteristic = new BluetoothGattCharacteristic(
            UUID.fromString(BluetoothLowEnergyUtils.CHARACTERISTIC_UUID),
            BluetoothGattCharacteristic.PROPERTY_READ | BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_READ | BluetoothGattCharacteristic.PERMISSION_WRITE
        );

        BluetoothGattCharacteristic identifier = new BluetoothGattCharacteristic(
            UUID.fromString(BluetoothLowEnergyUtils.IDENTIFIER_UUID),
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        );

        BluetoothGattService service = new BluetoothGattService(
            UUID.fromString(BluetoothLowEnergyUtils.SERVICE_UUID),
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        );

        service.addCharacteristic(characteristic);
        service.addCharacteristic(identifier);

        gattServer.addService(service);
    }

    private BluetoothGattServerCallback bluetoothGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onCharacteristicReadRequest(
            BluetoothDevice device, int requestId, int offset, BluetoothGattCharacteristic characteristic
        ) {
            if (verbose) Log.d(TAG, "onCharacteristicReadRequest()");
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic);
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, characteristic.getValue());
        }

        @Override
        public void onCharacteristicWriteRequest(
            BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic,
            boolean preparedWrite, boolean responseNeeded, int offset, byte[] value
        ) {
            if (verbose) Log.d(TAG, "onCharacteristicWriteRequest()");
            super.onCharacteristicWriteRequest(
                device, requestId, characteristic, preparedWrite, responseNeeded, offset, value
            );

            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value);

            if (characteristic.getUuid().toString() == BluetoothLowEnergyUtils.IDENTIFIER_UUID) {
                String ulid = new String(value, StandardCharsets.UTF_8);
                mapUlidMac.put(ulid, device.getAddress());

                HashMap<String, Object> mapInfoValue = new HashMap<>();
                mapInfoValue.put("type", BluetoothLowEnergyUtils.IDENTIFIER);
                mapInfoValue.put("macAddress", device.getAddress());
                mapInfoValue.put("ulid", ulid);
    
                eventConnectionSink.success(mapInfoValue);
            } else {
                String address = device.getAddress();
                ArrayList<byte[]> received = data.get(address);
                received.add(value);
                data.put(address, received);
    
                if (value[0] == BluetoothLowEnergyUtils.END_MESSAGE) {
                    eventMessageSink.success(data.get(address));
                    data.get(address).clear();
                }
            }
        }

        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            if (verbose) Log.d(TAG, "onConnectionStateChange(): " + device.getAddress());
            super.onConnectionStateChange(device, status, newState);

            mapMacDevice.put(device.getAddress(), device);
            data.put(device.getAddress(), new ArrayList<byte[]>());

            int state;
            HashMap<String, Object> mapInfoValue = new HashMap<>();
            mapInfoValue.put("type", BluetoothLowEnergyUtils.CONNECTION_STATUS);
            mapInfoValue.put("macAddress", device.getAddress());

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                state = BluetoothLowEnergyUtils.STATE_CONNECTED;
            } else {
                state = BluetoothLowEnergyUtils.STATE_DISCONNECTED;
            }

            mapInfoValue.put("state", state);

            eventConnectionSink.success(mapInfoValue);
        }
    };

    public void writeToCharacteristic(String message, String mac, String ulid) {
        BluetoothDevice device;
        if (mac == "") {
            device = mapMacDevice.get(mapUlidMac.get(ulid));
        } else {
            device = mapMacDevice.get(mac);
        }

        characteristic.setValue(message.getBytes(StandardCharsets.UTF_8));
        gattServer.notifyCharacteristicChanged(device, characteristic, false);
    }

    public List<HashMap<String, Object>> getConnectedDevices() {
        ArrayList<HashMap<String, Object>> btDevices = new ArrayList<>();
        List<BluetoothDevice> listBtDevices;

        listBtDevices = bluetoothManager.getConnectedDevices(BluetoothProfile.GATT);
        for(BluetoothDevice device : listBtDevices) {
            HashMap<String, Object> mapDeviceInfo = new HashMap<>();
            mapDeviceInfo.put("deviceName", device.getName());
            mapDeviceInfo.put("macAddress", device.getAddress());
            btDevices.add(mapDeviceInfo);
        }

        return btDevices;
    }

    public void closeGattServer() {
        if (verbose) Log.d(TAG, "closeGattServer()");
        gattServer.close();
        eventConnectionSink = null;
        eventMessageSink = null;
        eventConnectionChannel.setStreamHandler(null);
        eventMessageChannel.setStreamHandler(null);
    }

    public void setVerbose(boolean verbose) {
        if (verbose) Log.d(TAG, "setVerbose()");
        this.verbose = verbose;
    }

    private class MainThreadEventSink implements EventSink {
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
