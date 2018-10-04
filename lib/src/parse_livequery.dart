import "dart:convert";
import 'package:web_socket_channel/io.dart';
import 'parse_http_client.dart';
import 'dart:io';

class LiveQuery {
  final ParseHTTPClient client;
  var channel;
  Map<String, dynamic> connectMessage;
  Map<String, dynamic> subscribeMessage;
  Map<String, Function> eventCallbacks = {};

  LiveQuery(ParseHTTPClient client)
  : client = client {
    connectMessage = {
      "op": "connect",
      "applicationId": client.credentials.applicationId,
    };

    subscribeMessage = {
      "op": "subscribe",
      "requestId": 1,
      "query": {
        "className": null,
        "where": {},
      }
    };

  }

  subscribe(String className) async {
    //channel = await WebSocket.connect(client.liveQueryURL);
    var webSocket = await WebSocket.connect(client.liveQueryURL);
    channel = await new IOWebSocketChannel(webSocket);
    channel.sink.add(json.encode(connectMessage));
    subscribeMessage['query']['className'] = className;
    channel.sink.add(json.encode(subscribeMessage));
    channel.stream.listen((message) {
      Map<String, dynamic> actionData = json.decode(message);
      if (eventCallbacks.containsKey(actionData['op']))
          eventCallbacks[actionData['op']](actionData);
    });
  }

  void on(String op, Function callback){
    eventCallbacks[op] = callback;
  }

  void close(){
    channel.close();
  }

}