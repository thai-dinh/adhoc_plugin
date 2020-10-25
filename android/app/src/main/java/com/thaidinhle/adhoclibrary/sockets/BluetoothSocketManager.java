package com.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothSocket;

import java.io.IOException;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

public class BluetoothSocketManager {
    private static final String CLIENTS = "ad.hoc.lib.dev/bt.clients.socket";
    private static final String SERVERS = "ad.hoc.lib.dev/bt.servers.socket";

    private final MethodChannel clientSockets;
    private final MethodChannel serverSockets;
    
    private BluetoothClientSocketManager clientSocketManager;
    private BluetoothServerSocketManager serverSocketManager;

    public BluetoothSocketManager(FlutterEngine flutterEngine) {
        this.clientSocketManager = new BluetoothClientSocketManager();
        this.serverSocketManager = new BluetoothServerSocketManager();

        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        this.clientSockets = new MethodChannel(messenger, CLIENTS);
        this.clientSockets.setMethodCallHandler(
            (call, result) -> {
                setClientsMethodCall(call, result);
            }
        );

        this.serverSockets = new MethodChannel(messenger, SERVERS);
        this.serverSockets.setMethodCallHandler(
            (call, result) -> {
                setServersMethodCall(call, result);
            }
        );
    }

    private void setClientsMethodCall(MethodCall call, Result result) {
        final String macAddress = call.argument("address");

        int message;

        try {
            switch (call.method) {
                case "connect":
                    final boolean secure = call.argument("secure");
                    final String uuidString = call.argument("uuidString");
                    clientSocketManager.connect(macAddress, secure, uuidString);
                    break;
                case "close":
                    clientSocketManager.close(macAddress);
                    break;
                case "listen":
                    message = clientSocketManager.receiveMessage(macAddress);
                    result.success(message);
                    break;
                case "write":
                    message = call.argument("message");
                    clientSocketManager.sendMessage(macAddress, message);
                    break;
    
                default:
                    result.notImplemented();
                    break;
            }
        } catch (IOException | NoConnectionException error) {
            result.success(error.toString());
        }
    }

    private void setServersMethodCall(MethodCall call, Result result) {
        try {
            switch (call.method) {
                case "create":
                    final String name = call.argument("name");
                    final String uuidString = call.argument("uuidString");
                    final boolean secure = call.argument("secure");
                    serverSocketManager.createServerSocket(name, uuidString, secure);
                    break;
                case "accept":
                    BluetoothSocket socket = serverSocketManager.accept();
                    clientSocketManager.addSocket(socket);
                    result.success(socket.getRemoteDevice().getAddress());
                    break;
                case "close":
                    serverSocketManager.close();
                    break;

                default:
                    break;
            }
        } catch (IOException e) {
            result.success(e.toString());
        }
    }
}
