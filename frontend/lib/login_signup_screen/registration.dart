import '../metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../common/input_field.dart';
import '../common/password_field.dart';
import '../common/gradient_button.dart';
import '../utils.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _sendDataToBackend(BuildContext context) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    var passwordHash = sha256.convert(utf8.encode(password)).toString();
    final String patientAddress =
        context.read<MetaMaskProvider>().currentAddress;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/patient'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': passwordHash,
        'patient_address': patientAddress,
      }),
    );

    if (response.statusCode == 201) {
      showDialogCustom(context, "Registration successful");
    } else {
      showDialogCustom(context, "Registration failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Consumer<MetaMaskProvider>(
          builder: (context, provider, child) {
            bool showConnectButton =
                !provider.isConnected || !provider.isInOperatingChain;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    'Registration',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                    ),
                  ),
                  const SizedBox(height: 50),
                  InputField(
                    controller: _usernameController,
                    labelText: 'Username',
                  ),
                  const SizedBox(height: 20),
                  PasswordField(
                    controller: _passwordController,
                    labelText: 'Password',
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: () => {
                      if (showConnectButton)
                        {
                          context.read<MetaMaskProvider>().connect(),
                        }
                      else
                        {
                          _sendDataToBackend(context),
                        }
                    },
                    buttonText: 'Register',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
