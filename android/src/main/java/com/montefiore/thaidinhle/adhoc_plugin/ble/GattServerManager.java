package com.montefiore.thaidinhle.adhoc_plugin.ble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

public class GattServerManager {
    private static final String TAG = "[AdHocPlugin][GattServer]";
    private static final String EVENT_NAME = "ad.hoc.lib/ble.event.channel";

    private static final byte ANDROID_DISCOVERY  = 120;
    private static final byte ANDROID_STATE      = 121;
    private static final byte ANDROID_CONNECTION = 122;
    private static final byte ANDROID_CHANGES    = 123;
    private static final byte ANDROID_BOND       = 124;
    private static final byte ANDROID_DATA       = 125;
    private static final byte ANDROID_MTU        = 126;

    private boolean verbose;
    private Context context;

    private BluetoothGattServer gattServer;
    private BluetoothManager bluetoothManager;

    private HashMap<String, HashMap<Integer, ByteArrayOutputStream>> data;
    private HashMap<String, BluetoothDevice> mapMacDevice;

    private EventChannel eventChannel;
    private MainThreadEventSink eventSink;

    public GattServerManager(Context context) {
        this.verbose = false;
        this.context = context;
        this.data = new HashMap<>();
        this.mapMacDevice = new HashMap<>();
        this.register();
    }

/*--------------------------------Public methods------------------------------*/

    public void setVerbose(boolean verbose) {
        this.verbose = verbose;
    }

    public void setupEventChannel(BinaryMessenger messenger) {
        if (verbose) Log.d(TAG, "setupEventChannel()");

        eventChannel = new EventChannel(messenger, EVENT_NAME);
        eventChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                if (verbose) Log.d(TAG, "Channel: onListen()");
                eventSink = new MainThreadEventSink(events);
            }

            @Override
            public void onCancel(Object arguments) {
                if (verbose) Log.d(TAG, "Channel: onCancel()");
                eventSink = null;
                eventChannel.setStreamHandler(null);
                eventChannel = null;
            }
        });
    }

    public void openGattServer(BluetoothManager bluetoothManager, Context context) {
        if (verbose) Log.d(TAG, "openGattServer()");

        this.bluetoothManager = bluetoothManager;
        this.gattServer = bluetoothManager.openGattServer(context, bluetoothGattServerCallback);

        BluetoothGattCharacteristic characteristic = new BluetoothGattCharacteristic(
            UUID.fromString(BleUtils.CHARACTERISTIC_UUID),
            BluetoothGattCharacteristic.PROPERTY_READ | BluetoothGattCharacteristic.PROPERTY_WRITE | 
            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ | BluetoothGattCharacteristic.PERMISSION_WRITE
        );

        BluetoothGattService service = new BluetoothGattService(
            UUID.fromString(BleUtils.SERVICE_UUID),
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        );

        service.addCharacteristic(characteristic);

        gattServer.addService(service);
    }

    public void closeGattServer() {
        if (verbose) Log.d(TAG, "closeGattServer()");

        context.unregisterReceiver(receiver);
        gattServer.close();
        eventSink = null;
        eventChannel.setStreamHandler(null);
        eventChannel = null;
    }

    public List<HashMap<String, Object>> getConnectedDevices() {
        if (verbose) Log.d(TAG, "getConnectedDevices()");

        ArrayList<HashMap<String, Object>> btDevices = new ArrayList<>();
        List<BluetoothDevice> listBtDevices;

        listBtDevices = bluetoothManager.getConnectedDevices(BluetoothProfile.GATT);
        for(BluetoothDevice device : listBtDevices) {
            HashMap<String, Object> mapDeviceInfo = new HashMap<>();

            mapDeviceInfo.put("name", device.getName());
            mapDeviceInfo.put("mac", device.getAddress());

            btDevices.add(mapDeviceInfo);
        }

        return btDevices;
    }

    public boolean getBondState(String mac) {
        if (verbose) Log.d(TAG, "getBondState(): " + mac);

        BluetoothDevice device = mapMacDevice.get(mac);
        if (device == null)
            return false;

        if (verbose) Log.d(TAG, Integer.toString(device.getBondState()));

        return device.getBondState() == BluetoothDevice.BOND_BONDED;
    }

    public boolean createBond(String mac) {
        if (verbose) Log.d(TAG, "createBond(): " + mac);

        BluetoothDevice device = mapMacDevice.get(mac);
        if (device == null)
            return false;

        return device.createBond();
    }

    public void cancelConnection(String mac) {
        if (verbose) Log.d(TAG, "cancelConnection(): " + mac);

        BluetoothDevice device = mapMacDevice.get(mac);
        if (device == null)
            return;

        gattServer.cancelConnection(device);
    }

/*-------------------------------Private methods------------------------------*/

    private void register() {
        if (verbose) Log.d(TAG, "register()");

        final IntentFilter filter = 
            new IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED);
        context.registerReceiver(receiver, filter);
    }

    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            HashMap<String, Object> mapInfoValue = new HashMap<>();
            String action = intent.getAction();

            if (BluetoothDevice.ACTION_BOND_STATE_CHANGED.equals(action)) {
                BluetoothDevice device = 
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

                mapInfoValue.put("type", ANDROID_BOND);
                mapInfoValue.put("mac", device.getAddress());

                if (device.getBondState() == BluetoothDevice.BOND_BONDED) {
                    if (verbose) Log.d(TAG, "onReceive(): BOND_BONDED");

                    mapInfoValue.put("state", true);
                } else if (device.getBondState() == BluetoothDevice.BOND_BONDING) {
                    if (verbose) Log.d(TAG, "onReceive(): BOND_BONDING");
                } else {
                    if (verbose) Log.d(TAG, "onReceive(): BOND_NONE");

                    mapInfoValue.put("state", false);
                }

                eventSink.success(mapInfoValue);
            }
        }
    };

    private BluetoothGattServerCallback bluetoothGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onCharacteristicWriteRequest(
            BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic,
            boolean preparedWrite, boolean responseNeeded, int offset, byte[] value
        ) {
            if (verbose) Log.d(TAG, "onCharacteristicWriteRequest()");

            if(responseNeeded) {
                gattServer.sendResponse(
                    device, requestId, BluetoothGatt.GATT_SUCCESS, 0, new byte[0]
                );
            }

            String mac = device.getAddress();
            Integer id = new Integer(value[0]);
            byte flag = value[1];

            HashMap<Integer, ByteArrayOutputStream> buffer = data.get(mac);
            ByteArrayOutputStream byteBuffer = buffer.get(id);
            if (byteBuffer == null) {
                byteBuffer = new ByteArrayOutputStream();
            }

            try {
                byteBuffer.write(Arrays.copyOfRange(value, 2, value.length));
            } catch (IOException exception) {

            }

            if (flag == BleUtils.MESSAGE_END) {
                HashMap<String, Object> mapInfoValue = new HashMap<>();

                mapInfoValue.put("type", ANDROID_DATA);
                mapInfoValue.put("mac", mac);
                mapInfoValue.put("data", byteBuffer.toByteArray());

                eventSink.success(mapInfoValue);

                buffer.put(id, null);
            } else {
                buffer.put(id, byteBuffer);
            }

            data.put(mac, buffer);
        }

        @Override
        public void onConnectionStateChange(
            BluetoothDevice device, int status, int newState
        ) {
            if (verbose) Log.d(TAG, "onConnectionStateChange()");

            final String mac = device.getAddress();

            HashMap<String, Object> mapInfoValue = new HashMap<>();

            mapInfoValue.put("type", ANDROID_CONNECTION);
            mapInfoValue.put("mac", mac);

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                mapInfoValue.put("state", true);
                
                HashMap<Integer, ByteArrayOutputStream> map = new HashMap<>();
                data.put(mac, map);
                mapMacDevice.put(mac, device);
            } else {
                mapInfoValue.put("state", false);

                data.remove(mac);
                mapMacDevice.remove(mac);
            }

            eventSink.success(mapInfoValue);
        }

        @Override
        public void onMtuChanged(BluetoothDevice device, int mtu) {
            if (verbose) 
                Log.d(TAG, "onMtuChanged(): " + device.getAddress() + ", " + mtu);

            HashMap<String, Object> mapInfoValue = new HashMap<>();

            mapInfoValue.put("type", ANDROID_MTU);
            mapInfoValue.put("mac", device.getAddress());
            mapInfoValue.put("mtu", mtu);

            eventSink.success(mapInfoValue);
        }
    };

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
        public void error(
            final String errorCode, final String errorMessage, final Object errorDetails
        ) {
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
