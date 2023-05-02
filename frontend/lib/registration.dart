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

    // registration + create is done by the admin to avoid unauthorized txs
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
          late final Widget connectButton;
          if (provider.isConnected && provider.isInOperatingChain) {
            connectButton = Text(
              'Connected to ${provider.currentAddress}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            );
          } else if (provider.isConnected && !provider.isInOperatingChain) {
            connectButton = const Text(
              'Wrong chain. Please connect to ${MetaMaskProvider.operatingChain}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromARGB(255, 15, 15, 15)),
            );
          } else if (provider.isEnabled) {
            connectButton = MaterialButton(
              onPressed: () => context.read<MetaMaskProvider>().connect(),
              color: Color.fromARGB(255, 0, 0, 0),
              padding: const EdgeInsets.all(0),
              child: const Text(
                "Connect",
                style: TextStyle(
                  fontSize: 20.0,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            );
          } else {
            connectButton = const Text(
              'Please use a Web3 supported browser.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            );
          }
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
              connectButton,
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
