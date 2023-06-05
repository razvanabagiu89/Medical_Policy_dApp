import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import '../metamask_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class GrantAccess extends StatefulWidget {
  @override
  _GrantAccessState createState() => _GrantAccessState();
}

class _GrantAccessState extends State<GrantAccess> {
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController fileHashController = TextEditingController();

  Future<void> grantAccess(BuildContext context) async {
    final String employeeId = employeeIdController.text;
    final String fileHash = fileHashController.text;
    final patientAddress = context.read<MetaMaskProvider>().currentAddress;
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// blockchain //////////////////////////
    final signer = provider!.getSigner();
    final contract = await getAccessPolicyContract(signer);
    final tx = await contract.send('grantAccess', [
      patientAddress,
      hexStringToUint8List(fileHash),
      stringToBytes32(employeeId)
    ]);
    await tx.wait();
    List<dynamic> ids = await contract.call(
        'getPatientPolicyAllowedByMedicalRecordHash',
        [patientAddress, hexStringToUint8List(fileHash)]);
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/patient/$patientId/grant_access';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'employee_id': employeeId,
        'file_hash': fileHash,
        'patient_address': patientAddress,
      }),
    );

    if (response.statusCode == 200) {
      showDialogCustom(context, 'Access granted successfully');
    } else {
      showDialogCustom(
          context, 'Error granting access\nPlease try again later');
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
                labelText: 'Enter employee ID',
                controller: employeeIdController,
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter filehash',
                controller: fileHashController,
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () async {
                  await grantAccess(context);
                },
                buttonText: 'Grant',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
