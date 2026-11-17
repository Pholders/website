import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../shared/constants/app_constants.dart';

typedef RealtimeOrderEventCallback = void Function(
  String eventName,
  dynamic payload,
);

/// Thin wrapper around a Socket.IO client for realtime order events.
///
/// Handles order events for active pharmacy screens.
class RealtimeGateway {
  RealtimeGateway({String? wsUrl}) : wsUrl = wsUrl ?? defaultWsUrl;

  static String get defaultWsUrl => AppConstants.realtimeBaseUrl;

  final String wsUrl;
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Opens the socket with the given JWT. Safe to call multiple times;
  /// the previous connection is torn down first.
  void connect(
    String token, {
    RealtimeOrderEventCallback? onOrderEvent,
    void Function()? onReconnect,
  }) {
    disconnect();
    var hasConnected = false;
    _socket = io.io(
      wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    for (final eventName in [
      'order:incoming',
      'order:updated',
      'order:cancelled',
      'order:dispensed',
    ]) {
      _socket!
          .on(eventName, (payload) => onOrderEvent?.call(eventName, payload));
    }
    _socket!.on('connect', (_) {
      if (hasConnected) onReconnect?.call();
      hasConnected = true;
    });
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
