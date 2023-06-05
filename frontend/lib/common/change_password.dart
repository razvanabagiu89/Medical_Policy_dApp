import 'package:flutter/material.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import 'password_field.dart';

class ChangePassword extends StatefulWidget {
  @override
  ChangePasswordState createState() => ChangePasswordState();
}

class ChangePasswordState extends State<ChangePassword> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 15),
              PasswordField(
                labelText: 'Enter old password',
                controller: oldPasswordController,
              ),
              const SizedBox(height: 15),
              PasswordField(
                labelText: 'Enter new password',
                controller: newPasswordController,
              ),
              const SizedBox(height: 15),
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
