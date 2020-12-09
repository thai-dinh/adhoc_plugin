import 'package:adhoclibrary/adhoclibrary.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<ExampleApp> {
  WifiManager _wifiManager = WifiManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text('Register'),
                onPressed: _wifiManager.register,
              ),
              RaisedButton(
                child: Text('Unregister'),
                onPressed: _wifiManager.unregister,
              ),
              RaisedButton(
                child: Text('Start discovery'),
                onPressed: _wifiManager.discover,
              ),
              RaisedButton(
                child: Text('Connect'),
                onPressed: _wifiManager.connect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
