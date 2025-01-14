import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class RemoveEmployee extends StatefulWidget {
  @override
  RemoveEmployeeState createState() => RemoveEmployeeState();
}

class RemoveEmployeeState extends State<RemoveEmployee> {
  final TextEditingController removeEmployeeUsernameController =
      TextEditingController();

  Future<void> removeEmployee(BuildContext context) async {
    final String removeEmployeeUsername = removeEmployeeUsernameController.text;
    if (removeEmployeeUsername.isEmpty) {
      showDialogCustom(
          context, "Username can't be empty. Please enter valid values.");
      return;
    }
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/$id/employee/remove';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'username': removeEmployeeUsername,
      }),
    );

    if (response.statusCode == 200) {
      showDialogCustom(context, 'Employee removed successfully');
    } else {
      showDialogCustom(
          context, 'Error removing employee\nPlease try again later');
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
                labelText: 'Enter employee username',
                controller: removeEmployeeUsernameController,
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () async {
                  await removeEmployee(context);
                },
                buttonText: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
