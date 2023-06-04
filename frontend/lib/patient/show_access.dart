import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../user_provider.dart';
import 'package:provider/provider.dart';

class ShowAccessesScreen extends StatelessWidget {
  const ShowAccessesScreen({Key? key}) : super(key: key);

  Future<void> _showAccesses(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/patient/$patientId/all_policies';
    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );
    ////////////////////////// backend //////////////////////////

    if (response.statusCode == 200) {
      Navigator.pop(context);
      print("Show access successfully");
      print(response.body);
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Show Accesses')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _showAccesses(context);
              },
              child: const Text('Show'),
            ),
          ],
        ),
      ),
    );
  }
}
