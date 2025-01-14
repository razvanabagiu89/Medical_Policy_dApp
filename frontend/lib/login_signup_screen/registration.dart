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
import '../common/pallete.dart';
import '../common/custom_icon_button.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _sendDataToBackend(BuildContext context) async {
    final String username = usernameController.text;
    final String password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      showDialogCustom(context,
          "Username or password can't be empty. Please enter valid credentials.");
      return;
    }
    var passwordHash = sha256.convert(utf8.encode(password)).toString();
    final String patientAddress =
        context.read<MetaMaskProvider>().currentAddress;

    final response = await http.post(
      Uri.parse('http://localhost:8000/api/patient'),
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
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 800,
                        height: 160,
                      ),
                    ),
                    const Text(
                      'Register',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 35,
                      ),
                    ),
                    const SizedBox(height: 15),
                    InputField(
                      controller: usernameController,
                      labelText: 'Username',
                    ),
                    const SizedBox(height: 15),
                    PasswordField(
                      controller: passwordController,
                      labelText: 'Password',
                    ),
                    const SizedBox(height: 15),
                    provider.isConnected
                        ? Column(
                            children: [
                              Text(
                                'Connected to ${provider.currentAddress}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Pallete.gradient3,
                                ),
                              ),
                              const SizedBox(height: 15),
                              GradientButton(
                                onPressed: () => context
                                    .read<MetaMaskProvider>()
                                    .disconnect(),
                                buttonText: "Disconnect",
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                imagePath: 'assets/images/metamask.png',
                                onPressed: () =>
                                    context.read<MetaMaskProvider>().connect(),
                              ),
                              const SizedBox(width: 20),
                              CustomIconButton(
                                imagePath: 'assets/images/walletconnect.png',
                                onPressed: () => connectWalletConnect(),
                              ),
                            ],
                          ),
                    const SizedBox(height: 15),
                    GradientButton(
                      onPressed: () => {
                        provider.isConnected
                            ? _sendDataToBackend(context)
                            : showDialogCustom(
                                context, 'Please connect wallet'),
                      },
                      buttonText: 'Register',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
