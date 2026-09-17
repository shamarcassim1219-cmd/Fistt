import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static IO.Socket? _socket;

  static Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await ApiService.getToken();
    if (token == null) return;

    _socket = IO.io(
      ApiService.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );

    _socket!.connect();
  }

  static void joinRoom(String room) {
    _socket?.emit('join', room);
  }

  static void leaveRoom(String room) {
    _socket?.emit('leave', room);
  }

  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  static void off(String event) {
    _socket?.off(event);
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static bool get isConnected => _socket?.connected ?? false;
}
