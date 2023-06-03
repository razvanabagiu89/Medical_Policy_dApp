import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<FormState> _addFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _removeFormKey = GlobalKey<FormState>();
  String addInstitutionUsername = '';
  String removeInstitutionUsername = '';
  String institutionCIF = '';

  Future<void> addInstitution(BuildContext context) async {
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/institution/add';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': addInstitutionUsername,
        'CIF': institutionCIF,
      }),
    );

    if (response.statusCode == 201) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String institutionPassword = jsonResponse['password'].toString();
      print(institutionPassword);
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> removeInstitution(BuildContext context) async {
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/institution/remove';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': removeInstitutionUsername,
      }),
    );

    if (response.statusCode == 200) {
      print('Institution removed successfully');
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Form(
              key: _addFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter institution username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        addInstitutionUsername = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter institution CIF',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid CIF';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        institutionCIF = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_addFormKey.currentState!.validate()) {
                          await addInstitution(context);
                        }
                      },
                      child: Text('Add Institution'),
                    ),
                  ),
                ],
              ),
            ),
            Form(
              key: _removeFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter institution username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        removeInstitutionUsername = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_removeFormKey.currentState!.validate()) {
                          await removeInstitution(context);
                        }
                      },
                      child: Text('Remove Institution'),
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
