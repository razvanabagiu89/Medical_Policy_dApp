import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_provider.dart';
import 'metamask_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'utils.dart';
import 'package:hex/hex.dart';
import 'dart:typed_data';
import 'show_documents.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  String filehash = '';
  String patientUsername = '';
  late Future<List<String>> futureMedicalHashes;
  String doctorId = '';

  Future<void> requestAccess(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/doctor/$id/request_access';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'patient_username': patientUsername,
        'file_hash': filehash,
      }),
    );

    if (response.statusCode == 200) {
      print('Access requested');
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Form(
              key: _requestFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        patientUsername = value;
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
                        filehash = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_requestFormKey.currentState!.validate()) {
                          await requestAccess(context);
                        }
                      },
                      child: Text('Request Access'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final userModel = context.read<UserProvider>();
                        doctorId = userModel.getUserID();
                        futureMedicalHashes = fetchMedicalHashes(doctorId);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ShowDocuments(
                              futureMedicalHashes: futureMedicalHashes),
                        ));
                      },
                      child: Text('Show Documents'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
