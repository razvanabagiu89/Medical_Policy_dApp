import '../metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'add_mr.dart';
import 'grant.dart';
import 'revoke.dart';
import 'show_access.dart';
import 'add_wallet.dart';
import 'requests_page.dart';
import 'delete_mr.dart';
import '../common/gradient_button.dart';
import '../common/custom_consumer_button.dart';
import '../user_provider.dart';
import '../common/pallete.dart';
import '../common/change_password.dart';
import 'my_medical_records.dart';
import 'my_expenses.dart';
import '../common/custom_icon_button.dart';

class PatientDashboard extends StatefulWidget {
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  @override
  Widget build(BuildContext context) {
    final userModel = context.read<UserProvider>();
    return Scaffold(
      body: Stack(
        children: [
          // Main dashboard content
          Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                              'Profile',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Pallete.whiteColor,
                              ),
                            ),
                            backgroundColor: Pallete.backgroundColor,
                            contentTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Pallete.whiteColor,
                            ),
                            content: SingleChildScrollView(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SelectableText(
                                        'User ID: ${userModel.getUserID()}'),
                                    SelectableText(
                                        'Username: ${userModel.getUsername()}'),
                                    SelectableText(
                                        'User Type: ${userModel.getUserType()}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Consumer<MetaMaskProvider>(
                    builder: (context, provider, child) {
                      if (provider.isConnected) {
                        return Text(
                          'web3 address: ${provider.currentAddress}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      } else {
                        return const Text(
                          'Wallet not connected, limited access',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Patient Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                    ),
                  ),
                  const SizedBox(height: 15),
                  CustomConsumerButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMedicalRecord(),
                        ),
                      );
                    },
                    buttonText: 'Add medical record',
                  ),
                  const SizedBox(height: 15),
                  CustomConsumerButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return DeleteMedicalRecord();
                        },
                      );
                    },
                    buttonText: 'Delete medical record',
                  ),
                  const SizedBox(height: 15),
                  CustomConsumerButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return GrantAccess();
                        },
                      );
                    },
                    buttonText: 'Grant access',
                  ),
                  const SizedBox(height: 15),
                  CustomConsumerButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return RevokeAccess();
                        },
                      );
                    },
                    buttonText: 'Revoke access',
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowAccessesScreen(),
                        ),
                      );
                    },
                    buttonText: 'Show accesses',
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyMedicalRecords(),
                        ),
                      );
                    },
                    buttonText: 'My medical records',
                  ),
                  const SizedBox(height: 15),
                  CustomConsumerButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AddWallet();
                        },
                      );
                    },
                    buttonText: 'Add wallet',
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestsPage(),
                        ),
                      );
                    },
                    buttonText: 'Received requests',
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return ChangePassword();
                        },
                      );
                    },
                    buttonText: 'Change password',
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyExpenses(),
                        ),
                      );
                    },
                    buttonText: 'My Expenses',
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: CustomIconButton(
              imagePath: 'assets/images/groq.png',
              width: 160,
              height: 160,
              onPressed: () => _openAIChat(context),
            ),
          ),
        ],
      ),
    );
  }

  void _openAIChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AIChatDialog(),
    );
  }
}

class AIChatDialog extends StatefulWidget {
  @override
  _AIChatDialogState createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = []; // Stores chat messages

  void _sendMessage(String message) async {
    if (message.isNotEmpty) {
      // Add the user message to the chat
      setState(() {
        messages.add({'role': 'user', 'content': message});
      });

      // Clear the text field
      _controller.clear();

      try {
        final userModel = context.read<UserProvider>();
        final patientId = userModel.getUserID();

        final response = await http.post(
          Uri.parse(
              'http://localhost:8000/api/patient/$patientId/ai-assistant'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${userModel.getToken()}',
          },
          body: jsonEncode({'message': message}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiResponse = data['response'] ?? 'No response from AI.';
          _addAIResponse(aiResponse);
        } else {
          _addAIResponse('Failed to get a response from the AI.');
        }
      } catch (e) {
        _addAIResponse('Error communicating with the backend.');
      }
    }
  }

  void _addAIResponse(String response) {
    setState(() {
      messages.add({'role': 'ai', 'content': response});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Text(
              'AI Assistant',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message['role'] == 'user';

                  return Container(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message['content']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: isUser ? Colors.black : Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText:
                          'Hi! I am Meddico\'s AI Assistant. How can I help you today?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: () {
                    _sendMessage(_controller.text);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
