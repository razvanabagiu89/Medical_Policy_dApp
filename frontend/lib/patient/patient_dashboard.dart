import '../metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_mr.dart';
import 'grant.dart';
import 'revoke.dart';
import 'show_access.dart';
import 'add_wallet.dart';
import 'requests_page.dart';
import 'delete_mr.dart';
import '../common/gradient_button.dart';
import '../common/password_field.dart';
import '../utils.dart';
import '../common/custom_consumer_button.dart';

class PatientDashboard extends StatefulWidget {
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
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
              Consumer<MetaMaskProvider>(
                builder: (context, provider, child) {
                  if (provider.isConnected) {
                    return Text(
                      'web3 address: ${provider.currentAddress}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  } else {
                    return const Text(
                      'Wallet not connected, limited access',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 15),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 15),
              const Text(
                'Patient Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 15),
              CustomConsumerButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMedicalRecord(),
                    ),
                  );
                },
                buttonText: 'Add medical record',
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return DeleteMedicalRecord();
                    },
                  );
                },
                buttonText: 'Delete medical record',
              ),
              const SizedBox(height: 20),
              CustomConsumerButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return GrantAccess();
                    },
                  );
                },
                buttonText: 'Grant access',
              ),
              const SizedBox(height: 20),
              CustomConsumerButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return RevokeAccess();
                    },
                  );
                },
                buttonText: 'Revoke access',
              ),
              const SizedBox(height: 20),
              CustomConsumerButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowAccessesScreen(),
                    ),
                  );
                },
                buttonText: 'Show accesses',
              ),
              const SizedBox(height: 20),
              CustomConsumerButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddWallet();
                    },
                  );
                },
                buttonText: 'Add wallet',
              ),
              const SizedBox(height: 20),
              CustomConsumerButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestsPage(),
                    ),
                  );
                },
                buttonText: 'Received requests',
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
