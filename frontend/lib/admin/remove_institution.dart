import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class RemoveInstitution extends StatefulWidget {
  @override
  RemoveInstitutionState createState() => RemoveInstitutionState();
}

class RemoveInstitutionState extends State<RemoveInstitution> {
  final TextEditingController removeInstitutionUsernameController =
      TextEditingController();

  Future<void> removeInstitution(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final String removeInstitutionUsername =
        removeInstitutionUsernameController.text;
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/institution/remove';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'username': removeInstitutionUsername,
      }),
    );

    if (response.statusCode == 200) {
      showDialogCustom(context, 'Institution removed successfully');
    } else {
      showDialogCustom(context, "Error removing institution: ${response.body}");
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
                labelText: 'Enter institution username',
                controller: removeInstitutionUsernameController,
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () async {
                  await removeInstitution(context);
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
