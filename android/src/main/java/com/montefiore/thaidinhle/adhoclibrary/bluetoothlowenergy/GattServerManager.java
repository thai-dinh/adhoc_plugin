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
import android.os.SystemClock;
import android.util.Log;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
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
    private HashMap<String, HashMap<Integer, ArrayList<byte[]>>> data;
    private HashMap<String, BluetoothDevice> mapMacDevice;
    private HashMap<String, Short> mapMacMtu;
    private EventChannel eventConnectionChannel;
    private EventChannel eventMessageChannel;
    private MainThreadEventSink eventConnectionSink;
    private MainThreadEventSink eventMessageSink;

    public GattServerManager() {
        this.verbose = false;
        this.data = new HashMap<>();
        this.mapMacDevice = new HashMap<>();
        this.mapMacMtu = new HashMap<>();
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
            BluetoothGattCharacteristic.PROPERTY_READ | BluetoothGattCharacteristic.PROPERTY_WRITE | 
            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ | BluetoothGattCharacteristic.PERMISSION_WRITE
        );

        BluetoothGattService service = new BluetoothGattService(
            UUID.fromString(BluetoothLowEnergyUtils.SERVICE_UUID),
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        );

        service.addCharacteristic(characteristic);

        gattServer.addService(service);
    }

    private BluetoothGattServerCallback bluetoothGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onCharacteristicReadRequest(
            BluetoothDevice device, int requestId, int offset, BluetoothGattCharacteristic characteristic
        ) {
            if (verbose) Log.d(TAG, "onCharacteristicReadRequest()");
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, characteristic.getValue());
        }

        @Override
        public void onCharacteristicWriteRequest(
            BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic,
            boolean preparedWrite, boolean responseNeeded, int offset, byte[] value
        ) {
            if (verbose) Log.d(TAG, "onCharacteristicWriteRequest(): " + value[0] + ", " + value[1]);

            if(responseNeeded) {
                gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, new byte[0]);
            }

            String address = device.getAddress();
            Integer id = new Integer(value[1]);
            HashMap<Integer, ArrayList<byte[]>> buffer = data.get(address);
            ArrayList<byte[]> bytes = buffer.get(id);
            if (bytes == null)
                bytes = new ArrayList<byte[]>();
            bytes.add(value);
            buffer.put(id, bytes);
            data.put(address, buffer);

            if (value[0] == BluetoothLowEnergyUtils.END_MESSAGE) {
                HashMap<String, Object> mapInfoValue = new HashMap<>();
                mapInfoValue.put("message", data.get(address).get(id));
                mapInfoValue.put("macAddress", address);

                eventMessageSink.success(mapInfoValue);

                HashMap<Integer, ArrayList<byte[]>> received = data.get(address);
                received.remove(id);
                data.put(address, received);
            }
        }

        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            if (verbose) Log.d(TAG, "onConnectionStateChange(): " + device.getAddress() + ", " + newState);

            mapMacDevice.put(device.getAddress(), device);
            HashMap<Integer, ArrayList<byte[]>> bytes = new HashMap<>();
            data.put(device.getAddress(), bytes);

            int state;
            HashMap<String, Object> mapInfoValue = new HashMap<>();
            mapInfoValue.put("macAddress", device.getAddress());

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                gattServer.connect(device, false);
                state = BluetoothLowEnergyUtils.STATE_CONNECTED;
                mapMacMtu.put(device.getAddress(), new Short(BluetoothLowEnergyUtils.MIN_MTU));
            } else {
                gattServer.cancelConnection(device);
                state = BluetoothLowEnergyUtils.STATE_DISCONNECTED;
                mapMacDevice.remove(device.getAddress());
                mapMacMtu.remove(device.getAddress());
                data.remove(device.getAddress());
            }

            mapInfoValue.put("state", state);

            eventConnectionSink.success(mapInfoValue);
        }

        @Override
        public void onMtuChanged(BluetoothDevice device, int mtu) {
            if (verbose) Log.d(TAG, "onMtuChanged(): " + device.getAddress() + ", " + mtu);
            mapMacMtu.put(device.getAddress(), new Short((short) mtu));
        }

        @Override
        public void onNotificationSent (BluetoothDevice device, int status) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                if (verbose) Log.d(TAG, "onNotificationSent(): failed");
            } else {
                if (verbose) Log.d(TAG, "onNotificationSent(): success");
            }
        }
    };

    public boolean writeToCharacteristic(String message, String mac) throws IOException {
        if (verbose) Log.d(TAG, "writeToCharacteristic(): " + mac);

        BluetoothDevice device = mapMacDevice.get(mac);
        byte[] bytesMsg = message.getBytes(StandardCharsets.UTF_8);
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        int length = bytesMsg.length, mtu = mapMacMtu.get(mac).intValue() - 10;
        int start = 0, end = mtu;
        byte index = 1, cnt = 0;

        while (length > mtu) {
            outputStream.write(index);
            outputStream.write(Arrays.copyOfRange(bytesMsg, start, end));
            characteristic.setValue(outputStream.toByteArray());
            gattServer.notifyCharacteristicChanged(device, characteristic, false);

            index++;
            cnt++;
            start = end;
            end += mtu;
            length -= mtu;
            outputStream.reset();

            if (cnt == 30) {
                // notifyCharacteristicChanged can only send 30 consecutives in a burst
                SystemClock.sleep(100);
                cnt = 0;
            }
        }

        outputStream.reset();
        outputStream.write(BluetoothLowEnergyUtils.END_MESSAGE);
        outputStream.write(Arrays.copyOfRange(bytesMsg, start, bytesMsg.length));
        characteristic.setValue(outputStream.toByteArray());
        return gattServer.notifyCharacteristicChanged(device, characteristic, false);
    }

    public List<HashMap<String, Object>> getConnectedDevices() {
        if (verbose) Log.d(TAG, "getConnectedDevices()");

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

    public void cancelConnection(String mac) {
        if (verbose) Log.d(TAG, "cancelConnection()");

        BluetoothDevice device = mapMacDevice.get(mac);
        if (device == null)
            return;

        gattServer.cancelConnection(device);
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
