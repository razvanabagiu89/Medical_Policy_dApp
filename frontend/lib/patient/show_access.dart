import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../common/pallete.dart';

class ShowAccessesScreen extends StatelessWidget {
  const ShowAccessesScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _fetchAccesses(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    final url = 'http://localhost:8000/api/patient/$patientId/all_policies';
    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)["medical_record_policies"];
    } else {
      throw Exception("Failed to load policies");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 15),
            const Text(
              'My Accesses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchAccesses(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Failed to load data"));
                  } else {
                    var medicalRecordsPolicies =
                        snapshot.data! as Map<String, dynamic>;
                    return ListView.builder(
                      itemCount: medicalRecordsPolicies.keys.length,
                      itemBuilder: (context, index) {
                        var recordHash =
                            medicalRecordsPolicies.keys.elementAt(index);
                        var wallets = medicalRecordsPolicies[recordHash];

                        if (wallets.length == 0 ||
                            wallets is! Map<String, dynamic>) {
                          return ListTile(
                            title: SelectableText("Record Hash: $recordHash"),
                            subtitle: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                      text: 'No granted access',
                                      style: TextStyle(color: Colors.red))
                                ],
                              ),
                            ),
                          );
                        } else {
                          var walletsMap = wallets;
                          var walletsText = walletsMap.entries.map((entry) {
                            var walletAddress = entry.key;
                            var accesses = entry.value;
                            var accessesList = accesses as List<dynamic>;
                            return TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                    text:
                                        'Granted from wallet: $walletAddress\nID\'s allowed: ${accessesList.join(', ')}',
                                    style: const TextStyle(
                                        color: Pallete.gradient3)),
                              ],
                            );
                          }).toList();
                          return ListTile(
                            title: SelectableText("Record Hash: $recordHash"),
                            subtitle:
                                RichText(text: TextSpan(children: walletsText)),
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
