import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import 'show_documents.dart';
import '../common/input_field.dart';
import '../common/gradient_button.dart';
import '../common/password_field.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final TextEditingController patientUsernameController =
      TextEditingController();
  final TextEditingController filehashController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  late Future<List<String>> futureMedicalHashes;
  String employeeId = '';

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
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 15),
              const Text(
                'Employee Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
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
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await requestAccess(context);
                },
                buttonText: 'Request Access',
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  final userModel = context.read<UserProvider>();
                  employeeId = userModel.getUserID();
                  futureMedicalHashes = fetchMedicalHashes(employeeId);
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return ShowDocuments(
                          futureMedicalHashes: futureMedicalHashes);
                    },
                  );
                },
                buttonText: 'Show Documents',
              ),
              const SizedBox(height: 20),
              PasswordField(
                labelText: 'Enter old password',
                controller: oldPasswordController,
              ),
              const SizedBox(height: 15),
              PasswordField(
                labelText: 'Enter new password',
                controller: newPasswordController,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await changePassword(
                      context, oldPasswordController, newPasswordController);
                },
                buttonText: 'Change your password',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
