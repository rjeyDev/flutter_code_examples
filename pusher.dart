import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_pusher/pusher.dart';

class PusherService {
  String lastConnectionState;
  Channel channel;
  Function addSms;
  StreamController<String> _eventData = StreamController<String>();
  Stream get eventStream => _eventData.stream;

  PusherService({this.addSms});

  Future<void> initPusher() async {
    try {
      await Pusher.init('eed31aeea3143b907f6d', PusherOptions(cluster: 'ap2'));
      print('init');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  void connectPusher() {
    Pusher.connect(
        onConnectionStateChange: (ConnectionStateChange connectionState) async {
      lastConnectionState = connectionState.currentState;
      print(lastConnectionState);
    }, onError: (ConnectionError e) {
      print("Error: ${e.message}");
    }).then((value) => print('success'));
  }

  Future<void> subscribePusher(String channelName) async {
    channel = await Pusher.subscribe(channelName);
    print('subscribe');
  }

  void unSubscribePusher(String channelName) {
    Pusher.unsubscribe(channelName);
  }

  void bindPusher() async {
    await channel.bind('code-event', (onEvent) {
      addSms(json.decode(onEvent.data));
    });
    print('bind');
  }

  Future<void> firePusher(String channelName) async {
    await initPusher();
    connectPusher();
    await subscribePusher(channelName);
    bindPusher();
  }
}
