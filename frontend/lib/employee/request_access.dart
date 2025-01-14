import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class RequestAccess extends StatefulWidget {
  @override
  RequestAccessState createState() => RequestAccessState();
}

class RequestAccessState extends State<RequestAccess> {
  final TextEditingController patientUsernameController =
      TextEditingController();
  final TextEditingController filehashController = TextEditingController();

  Future<void> requestAccess(BuildContext context) async {
    final String filehash = filehashController.text;
    final String patientUsername = patientUsernameController.text;
    if (filehash.isEmpty || patientUsername.isEmpty) {
      showDialogCustom(context,
          "Username or filehash can't be empty. Please enter valid values.");
      return;
    }
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/employee/$id/request_access';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'patient_username': patientUsername,
        'file_hash': filehash,
      }),
    );

    if (response.statusCode == 200) {
      showDialogCustom(context, 'Access requested');
    } else {
      showDialogCustom(
          context, 'Error requesting access\nPlease try again later');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter patient username',
                controller: patientUsernameController,
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter employee medical hash',
                controller: filehashController,
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () async {
                  await requestAccess(context);
                },
                buttonText: 'Request',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
