import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class InstitutionDashboard extends StatefulWidget {
  @override
  _InstitutionDashboardState createState() => _InstitutionDashboardState();
}

class _InstitutionDashboardState extends State<InstitutionDashboard> {
  final GlobalKey<FormState> _addDoctorFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _removeDoctorFormKey = GlobalKey<FormState>();
  String addDoctorUsername = '';
  String removeDoctorUsername = '';
  String doctorFullName = '';

  Future<void> addDoctor(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/$id/doctor/add';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': addDoctorUsername,
        'full_name': doctorFullName,
      }),
    );

    if (response.statusCode == 201) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String doctorPassword = jsonResponse['password'].toString();
      print(doctorPassword);
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> removeDoctor(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/$id/doctor/remove';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': removeDoctorUsername,
      }),
    );

    if (response.statusCode == 200) {
      print('Doctor removed successfully');
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Institution Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Add Doctor', style: TextStyle(fontSize: 18)),
            Form(
              key: _addDoctorFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter doctor username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        addDoctorUsername = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter doctor full name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid full name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        doctorFullName = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_addDoctorFormKey.currentState!.validate()) {
                          await addDoctor(context);
                          print(
                              'Adding doctor: $addDoctorUsername, $doctorFullName');
                        }
                      },
                      child: Text('Add Doctor'),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            Text('Remove Doctor', style: TextStyle(fontSize: 18)),
            Form(
              key: _removeDoctorFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter doctor username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        removeDoctorUsername = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_removeDoctorFormKey.currentState!.validate()) {
                          // Remove doctor logic
                          await removeDoctor(context);
                          print('Removing doctor: $doctorFullName');
                        }
                      },
                      child: Text('Remove Doctor'),
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
