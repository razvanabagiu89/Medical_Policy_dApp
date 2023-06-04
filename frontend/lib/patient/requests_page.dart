import 'package:flutter/material.dart';
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
    final response = await http
        .get(Uri.parse('http://localhost:8000/api/patient/$id/requests'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body)['requests'];
      return jsonResponse;
    } else {
      throw Exception('Failed to load requests');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Requests')),
      body: Center(
        child: FutureBuilder<List<dynamic>>(
          future: futureRequests,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data![index]['from']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('ID: ${snapshot.data![index]['ID']}'),
                        Text(
                            'Belongs to: ${snapshot.data![index]['belongs_to']}'),
                        SelectableText(
                            'Document: ${snapshot.data![index]['document']}'),
                      ],
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
