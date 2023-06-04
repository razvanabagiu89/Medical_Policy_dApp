import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import '../metamask_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import '../utils.dart';

class GrantAccess extends StatefulWidget {
  @override
  _GrantAccessState createState() => _GrantAccessState();
}

class _GrantAccessState extends State<GrantAccess> {
  final _formKey = GlobalKey<FormState>();
  String _employeeId = '';
  String _fileHash = '';

  Future<void> grantAccess(BuildContext context) async {
    final patientAddress = context.read<MetaMaskProvider>().currentAddress;
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// blockchain //////////////////////////
    final signer = provider!.getSigner();
    final contract = await getAccessPolicyContract(signer);
    final tx = await contract.send('grantAccess', [
      patientAddress,
      hexStringToUint8List(_fileHash),
      stringToBytes32(_employeeId)
    ]);
    await tx.wait();
    List<dynamic> ids = await contract.call(
        'getPatientPolicyAllowedByMedicalRecordHash',
        [patientAddress, hexStringToUint8List(_fileHash)]);
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/patient/$patientId/grant_access';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'employee_id': _employeeId,
        'file_hash': _fileHash,
        'patient_address': patientAddress,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      print("Access granted successfully");
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grant Access'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter employee ID',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid employee ID';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _employeeId = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter file hash',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid file hash';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _fileHash = value;
                  });
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await grantAccess(context);
                    }
                  },
                  child: Text('Grant Access'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
