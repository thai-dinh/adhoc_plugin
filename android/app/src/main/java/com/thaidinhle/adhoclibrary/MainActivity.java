package com.thaidinhle.adhoclibrary;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import java.io.IOException;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "ad.hoc.library.dev/bluetooth.channel";
    private static final String STREAM = "ad.hoc.library.dev/bluetooth.stream";
    private static final String WIFI = "ad.hoc.library.dev/wifi";
    private static final String BTSOCKET = "ad.hoc.lib.dev/bt.socket";

    private final BluetoothAdHocManager bluetooth = new BluetoothAdHocManager(true, getContext());
    private final WifiAdHocManager wifiManager = new WifiAdHocManager(true, getContext());
    private final BluetoothSocketManager socketManager = new BluetoothSocketManager();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        EventChannel eventChannel = 
            new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STREAM);
        bluetooth.setStreamHandler(eventChannel);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    bluetooth.onMethodCall(call, result);
                }
            );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BTSOCKET)
            .setMethodCallHandler(
                (call, result) -> {
                    final String address = "address";
                    try {
                        switch (call.method) {
                            case "connect":
                                socketManager.connect(call.argument(address), false);
                                break;
                            case "close":
                                socketManager.close(call.argument(address));
                                break;
                            case "listen":
                                final int value = socketManager.receiveMessage(call.argument(address));
                                result.success(value);
                                break;
                            case "write":
                                socketManager.sendMessage(call.argument(address), null);
                                break;
    
                            default:
                                break;
                        }   
                    } catch (IOException e) {
                        //TODO: handle exception
                    } catch (NoConnectionException e) {

                    }
                }
            );

        MethodChannel wifiChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), WIFI);
        wifiChannel.setMethodCallHandler(
            (call, result) -> {
                wifiManager.onMethodCall(call, result);
            }
        );
    }
}
