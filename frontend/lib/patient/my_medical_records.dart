import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../employee/display_document.dart';

class MyMedicalRecords extends StatefulWidget {
  @override
  _MyMedicalRecordsState createState() => _MyMedicalRecordsState();
}

class _MyMedicalRecordsState extends State<MyMedicalRecords> {
  String? medicalHash;
  List<String> medicalHashes = [];

  @override
  void initState() {
    super.initState();
    fetchMedicalHashes();
  }

  Future<void> fetchMedicalHashes() async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    final url = Uri.parse(
        'https://localhost:8000/api/patient/$patientId/all_medical_records');
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
        medicalHashes = List<String>.from(data['all_medical_records']);
        if (medicalHashes.isNotEmpty) {
          medicalHash = medicalHashes[0];
        }
      });
    } else {
      throw Exception('Failed to load medical hashes');
    }
  }

  void onView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            medicalHash == null
                ? Container()
                : Expanded(child: DisplayDocument(medicalHash: medicalHash!)),
            medicalHashes.isEmpty
                ? CircularProgressIndicator()
                : medicalHash == null
                    ? SizedBox.shrink()
                    : DropdownButton<String>(
                        value: medicalHash,
                        items: medicalHashes
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            if (newValue != null) {
                              medicalHash = newValue;
                            }
                          });
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
