import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import '../user_provider.dart';
import '../utils.dart';
import '../common/pallete.dart';

class AddMedicalRecord extends StatefulWidget {
  const AddMedicalRecord({Key? key}) : super(key: key);
  @override
  _AddMedicalRecordState createState() => _AddMedicalRecordState();
}

class _AddMedicalRecordState extends State<AddMedicalRecord> {
  late DropzoneViewController controller;
  String message = 'Drop your document here';
  bool highlighted = false;

  Future<void> _sendDataToBackend(
      BuildContext context, String fileName, List<int> fileBytes) async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();

    ////////////////////////// blockchain //////////////////////////
    final signer = provider!.getSigner();
    final contract = await getPatientRegistryContract(signer);
    String medicalRecordHash = computeHash(fileName);
    List<int> medicalRecordBytes32 = convertStringToBytes(medicalRecordHash);
    final tx = await contract
        .send('addMedicalRecord', [int.parse(patientId), medicalRecordBytes32]);
    await tx.wait();
    ////////////////////////// backend //////////////////////////
    final fileData = base64Encode(fileBytes);
    final requestBody = jsonEncode({
      'patient_id': patientId,
      'filename': fileName,
      'filedata': fileData,
      'medical_record_hash':
          utf8.decode(medicalRecordBytes32), // send as string
    });

    final response = await http.post(
      Uri.parse('http://localhost:8000/api/patient/$patientId/medical_record'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: requestBody,
    );

    if (response.statusCode == 201) {
      showDialogCustom(context, 'Medical record added successfully');
    } else {
      showDialogCustom(
          context, 'Error adding medical record\nPlease try again later');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Pallete.backgroundColor,
      ),
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 15),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 600.0,
                  width: 600.0,
                  decoration: BoxDecoration(
                    color: Pallete.backgroundColor,
                    border: Border.all(
                      color:
                          highlighted ? Pallete.gradient3 : Pallete.borderColor,
                      width: 10,
                    ),
                  ),
                  child: Stack(
                    children: [
                      const SizedBox(height: 20),
                      DropzoneView(
                        operation: DragOperation.copy,
                        cursor: CursorType.grab,
                        onCreated: (ctrl) => controller = ctrl,
                        onLoaded: () => () {},
                        onError: (ev) => () {},
                        onHover: () {
                          setState(() => highlighted = true);
                        },
                        onLeave: () {
                          setState(() => highlighted = false);
                        },
                        onDrop: (ev) async {
                          setState(() {
                            message = '${ev.name} loaded';
                            highlighted = false;
                          });
                          final bytes = await controller.getFileData(ev);
                          _sendDataToBackend(context, ev.name, bytes);
                        },
                      ),
                      Center(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Pallete.whiteColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
