import 'metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'add_mr.dart';
import 'grant.dart';
import 'revoke.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<MetaMaskProvider>(
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
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Add Medical Record screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddMedicalRecord()));
              },
              child: const Text('Add Medical Record'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Grant Access screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GrantAccess()));
              },
              child: const Text('Grant Access'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Revoke Access screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RevokeAccess()));
              },
              child: const Text('Revoke Access'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Show Accesses screen
              },
              child: const Text('Show Accesses'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Add Wallet screen
              },
              child: const Text('Add Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
