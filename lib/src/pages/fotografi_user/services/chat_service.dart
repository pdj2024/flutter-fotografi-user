import 'package:mpjnew/src/pages/core/api_singleton.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/http_connection_options.dart';

import 'package:signalr_netcore/itransport.dart';


class SignalRService {
  HubConnection? _hubConnection;

  Future<void> startConnection() async {
      final hubUrl = 'http://43.228.212.41:15/api/chathub';
      final token = await apiClient.getIdToken();
      final role = apiClient.getRole() ?? 'customer';

       if (token == null || token.isEmpty) {
        print("[SignalR] ❌ Gagal connect: token kosong");
        return;
      }



      _hubConnection = HubConnectionBuilder()
        .withUrl(
          'http://43.228.212.41:15/api/chathub?role=$role',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
             transport: HttpTransportType.WebSockets, // paksa langsung WS
          ),
        )
        .build();



    try {
      await _hubConnection?.start();
      print('🎉 Connected to SignalR successfully! 🎉'); // 🎉 emoji saat berhasil
      receiveMessages(); // mulai listen setelah connect
    } catch (e) {
      print('❌ Failed to connect: $e');
    }
  }

  void receiveMessages() {
    _hubConnection?.on('ReceiveMessage', (message) {
      print('Received: ${message?[0]}');
    });
  }

  void sendMessage(String user, String message) {
    _hubConnection?.invoke('SendMessage', args: [user, message]);
  }

  Future<void> stopConnection() async {
    await _hubConnection?.stop();
  }
}