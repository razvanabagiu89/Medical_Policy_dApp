import 'metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'metamask_provider.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Consumer<MetaMaskProvider>(
          builder: (context, provider, child) {
            if (provider.isConnected) {
              return Text(
                'Your web3 address: ${provider.currentAddress}',
                style: const TextStyle(fontSize: 24.0),
              );
            } else {
              return Text(
                'Please connect to MetaMask',
                style: const TextStyle(fontSize: 24.0),
              );
            }
          },
        ),
      ),
    );
  }
}

