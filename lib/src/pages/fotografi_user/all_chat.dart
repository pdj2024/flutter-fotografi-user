import 'package:flutter/material.dart';
import 'services/chat_service.dart';


class AllChat extends StatefulWidget {
  
 

  @override
  _AllChatState createState() => _AllChatState();
}

class _AllChatState extends State<AllChat> {
  final TextEditingController _messageController = TextEditingController();
  List<String> messages = [];
  late SignalRService signalRService;

  void _sendMessage() {
    String message = _messageController.text;
    if (message.isNotEmpty) {
      setState(() {
        messages.add("You: $message"); // Add the sent message to the list
      });
      signalRService.sendMessage('user', message);
      _messageController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    signalRService = SignalRService();
    signalRService.startConnection();

    // Receive messages from SignalR and add them to the chat
    // signalRService.receiveMessages((receivedMessage) {
    //   setState(() {
    //     messages.add(
    //         "Server: $receivedMessage"); // Add received message to the list
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isUserMessage = messages[index].startsWith("You: ");
                return Align(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5.0),
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color:
                          isUserMessage ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      messages[index],
                      style: TextStyle(
                        color: isUserMessage ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}