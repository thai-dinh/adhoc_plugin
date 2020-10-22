package com.thaidinhle.adhoclibrary;

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

        BinaryMessenger binaryMessenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        this.clientSockets = new MethodChannel(binaryMessenger, CLIENTS);
        this.clientSockets.setMethodCallHandler(
            (call, result) -> {
                setClientsMethodCall(call, result);
            }
        );

        this.serverSockets = new MethodChannel(binaryMessenger, SERVERS);
        this.serverSockets.setMethodCallHandler(
            (call, result) -> {
                setServersMethodCall(call, result);
            }
        );
    }

    private void setClientsMethodCall(MethodCall call, Result result) {
        final String macAddress = call.argument("address");

        try {
            switch (call.method) {
                case "create":
                    final boolean secure = call.argument("secure");
                    clientSocketManager.createSocket(macAddress, secure);
                    break;
                case "connect":
                    clientSocketManager.connect(macAddress);
                    break;
                case "close":
                    clientSocketManager.close(macAddress);
                    break;
                case "listen": // %TODO: adjust message format
                    Object message = clientSocketManager.receiveMessage(macAddress);
                    result.success(message);
                    break;
                case "write":
                    // Object msg = call.argument("message"); // %TODO: adjust message format
                    clientSocketManager.sendMessage(macAddress, null);
                    break;
    
                default:
                    break;
            }
        } catch (IOException e) {
            //TODO: handle exception
        } catch (NoConnectionException e) {
            //TODO: handle exception
        }
    }

    private void setServersMethodCall(MethodCall call, Result result) {
        final String name = call.argument("name");
        
        try {
            switch (call.method) {
                case "create":
                    final boolean secure = call.argument("secure");
                    final String uuidString = call.argument("uuidString");
                    serverSocketManager.createServerSocket(name, uuidString, secure);
                    break;
                case "accept":
                    clientSocketManager.addSocket(serverSocketManager.accept(name));
                    break;
                case "close":
                    serverSocketManager.close(name);
                    break;

                default:
                    break;
            }
        } catch (IOException e) {
            //TODO: handle exception
        }
    }
}
