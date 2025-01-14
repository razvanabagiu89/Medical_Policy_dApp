import 'package:flutter/material.dart';
import 'package:frontend/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  late Future<List<dynamic>> futureRequests;

  @override
  void initState() {
    super.initState();
    futureRequests = fetchRequests();
  }

  Future<List<dynamic>> fetchRequests() async {
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/patient/$id/requests'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body)['requests'];
      return jsonResponse;
    } else {
      throw Exception('Failed to load requests');
    }
  }

  Future<http.Response> deleteRequest(
      String employeeId, String documentHash) async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    return http.delete(
      Uri.parse('http://localhost:8000/api/patient/$patientId/delete_request'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'employee_id': employeeId,
        'document_hash': documentHash,
      }),
    );
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
              'Requests',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: futureRequests,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Failed to load requests'));
                  } else {
                    var requests = snapshot.data!;
                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        var request = requests[index];
                        return Dismissible(
                          key: Key(requests[index].toString()),
                          onDismissed: (direction) async {
                            var request = requests[index];
                            await deleteRequest(
                                request['ID'], request['document']);
                            setState(() {
                              requests.removeAt(index);
                            });
                            showDialogCustom(context, '$request dismissed');
                          },
                          child: ListTile(
                            title: Text(request['from']),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () async {
                                var request = requests[index];
                                await deleteRequest(
                                    request['ID'], request['document']);
                                setState(() {
                                  requests.removeAt(index);
                                });
                                showDialogCustom(context, '$request dismissed');
                              },
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText('ID: ${request['ID']}'),
                                SelectableText(
                                    'Belongs to: ${request['belongs_to']}'),
                                SelectableText(
                                    'Document: ${request['document']}'),
                              ],
                            ),
                          ),
                        );
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
