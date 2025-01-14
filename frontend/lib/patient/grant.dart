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
import '../common/dropdown.dart';

class GrantAccess extends StatefulWidget {
  @override
  _GrantAccessState createState() => _GrantAccessState();
}

class _GrantAccessState extends State<GrantAccess> {
  final TextEditingController employeeIdController = TextEditingController();
  String? fileHash = '';
  List<String> fileHashes = [];

  @override
  void initState() {
    super.initState();
    fetchFileHashes();
  }

  Future<void> fetchFileHashes() async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    final url = Uri.parse(
        'http://localhost:8000/api/patient/$patientId/all_medical_records');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        fileHashes = List<String>.from(data['all_medical_records']);
        if (fileHashes.isNotEmpty) {
          fileHash =
              fileHashes[0]; // Set the first file hash as the initial value
        }
      });
    } else {
      throw Exception('Failed to load file hashes');
    }
  }

  Future<void> grantAccess(BuildContext context) async {
    final String employeeId = employeeIdController.text;
    final patientAddress = context.read<MetaMaskProvider>().currentAddress;
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// blockchain //////////////////////////
    final signer = provider!.getSigner();
    final contract = await getAccessPolicyContract(signer);
    if (fileHash != null) {
      final tx = await contract.send('grantAccess', [
        patientAddress,
        hexStringToUint8List(fileHash!),
        stringToBytes32(employeeId)
      ]);
      await tx.wait();
    }
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/patient/$patientId/grant_access';
    if (fileHash != null) {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userModel.getToken()}',
        },
        body: jsonEncode(<String, String>{
          'employee_id': employeeId,
          'file_hash': fileHash!,
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
              fileHashes.isEmpty
                  ? CircularProgressIndicator()
                  : fileHash == null
                      ? SizedBox.shrink()
                      : InputDropdown(
                          value: fileHash!,
                          items: fileHashes,
                          onChanged: (String? newValue) {
                            setState(() {
                              if (newValue != null) {
                                fileHash = newValue;
                              }
                            });
                          },
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
