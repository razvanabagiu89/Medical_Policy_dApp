import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import 'package:flutter_web3/flutter_web3.dart';

class DeleteMedicalRecord extends StatefulWidget {
  @override
  DeleteMedicalRecordState createState() => DeleteMedicalRecordState();
}

class DeleteMedicalRecordState extends State<DeleteMedicalRecord> {
  final _formKey = GlobalKey<FormState>();
  String _fileHash = '';

  Future<void> deleteMedicalRecord(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// blockchain //////////////////////////
    final signer = provider!.getSigner();
    final contract = await getPatientRegistryContract(signer);
    List<int> medicalRecordBytes32 = hexStringToUint8List(_fileHash);
    final tx = await contract.send(
        'deleteMedicalRecord', [int.parse(patientId), medicalRecordBytes32]);
    await tx.wait();
    // final tx2 = await contract
    //     .call('getPatientMedicalRecordsHashes', [int.parse(patientId)]);
    // print(tx2);
    ////////////////////////// backend //////////////////////////
    final url =
        'http://localhost:5000/api/patient/$patientId/delete_medical_record';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'patient_id': patientId,
        'medical_record_hash': _fileHash,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context);
      print("Medical record deleted successfully");
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Medical Record'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                      await deleteMedicalRecord(context);
                    }
                  },
                  child: Text('Delete Medical Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
