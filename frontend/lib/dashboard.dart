import 'metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_mr.dart';
import 'grant.dart';
import 'revoke.dart';
import 'show_access.dart';
import 'add_wallet.dart';
import 'requests_page.dart';
import 'delete_mr.dart';

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
                    'MetaMask not connected, only read-only access',
                    style: const TextStyle(fontSize: 24.0),
                  );
                }
              },
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DeleteMedicalRecord()));
              },
              child: const Text('Delete Medical Record'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => GrantAccess()));
              },
              child: const Text('Grant Access'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => RevokeAccess()));
              },
              child: const Text('Revoke Access'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShowAccessesScreen()),
                );
              },
              child: const Text('Show Accesses'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddWallet()),
                );
              },
              child: const Text('Add Wallet'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequestsPage()),
                );
              },
              child: const Text('Received Requests'),
            ),
          ],
        ),
      ),
    );
  }
}
