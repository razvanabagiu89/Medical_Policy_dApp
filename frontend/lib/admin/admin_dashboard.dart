import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<FormState> _addFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _removeFormKey = GlobalKey<FormState>();
  final TextEditingController addInstitutionUsername = TextEditingController();
  final TextEditingController removeInstitutionUsername =
      TextEditingController();
  final TextEditingController institutionCIF = TextEditingController();

  Future<void> addInstitution(BuildContext context) async {
    final String addInstitutionUsername = this.addInstitutionUsername.text;
    final String institutionCIF = this.institutionCIF.text;
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
    final String removeInstitutionUsername =
        this.removeInstitutionUsername.text;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter institution username',
                controller: addInstitutionUsername,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter institution CIF',
                controller: institutionCIF,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid CIF';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  if (_addFormKey.currentState!.validate()) {
                    await addInstitution(context);
                  }
                },
                buttonText: 'Add Institution',
              ),
              const SizedBox(height: 20),
              InputField(
                labelText: 'Enter institution username',
                controller: removeInstitutionUsername,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  if (_removeFormKey.currentState!.validate()) {
                    await removeInstitution(context);
                  }
                },
                buttonText: 'Remove Institution',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
