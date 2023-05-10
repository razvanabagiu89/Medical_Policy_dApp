import 'metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'utils.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:flutter/services.dart';

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
    final String patientAddress =
        context.read<MetaMaskProvider>().currentAddress;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/patient'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'patient_address': patientAddress,
      }),
    );

    if (response.statusCode == 201) {
      print("Registration successful");
    } else {
      print("Registration failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Consumer<MetaMaskProvider>(
        builder: (context, provider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: () => _sendDataToBackend(context),
                child: Text('Register'),
              ),
            ],
          );
        },
      ),
    );
  }
}
