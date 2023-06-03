import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import 'show_documents.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  String filehash = '';
  String patientUsername = '';
  late Future<List<String>> futureMedicalHashes;
  String employeeId = '';

  Future<void> requestAccess(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/employee/$id/request_access';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'patient_username': patientUsername,
        'file_hash': filehash,
      }),
    );

    if (response.statusCode == 200) {
      print('Access requested');
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Form(
              key: _requestFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        patientUsername = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter file hash',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid file hash';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        filehash = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_requestFormKey.currentState!.validate()) {
                          await requestAccess(context);
                        }
                      },
                      child: Text('Request Access'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final userModel = context.read<UserProvider>();
                        employeeId = userModel.getUserID();
                        futureMedicalHashes = fetchMedicalHashes(employeeId);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ShowDocuments(
                              futureMedicalHashes: futureMedicalHashes),
                        ));
                      },
                      child: Text('Show Documents'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
