import 'package:flutter/material.dart';
import 'package:frontend/common/pallete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../user_provider.dart';

class CompareInstitutions extends StatefulWidget {
  @override
  _CompareInstitutionsState createState() => _CompareInstitutionsState();
}

class _CompareInstitutionsState extends State<CompareInstitutions> {
  List<dynamic>? dbInstitutions;
  List<dynamic>? blockchainInstitutions;

  @override
  void initState() {
    super.initState();
    fetchInstitutions();
  }

  Future<void> fetchInstitutions() async {
    final userModel = context.read<UserProvider>();
    var dbResponse = await http.get(
      Uri.parse('https://localhost:8000/get_db_institutions'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
    );

    var blockchainResponse = await http.get(
      Uri.parse('https://localhost:8000/get_blockchain_institutions'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
    );

    if (dbResponse.statusCode == 200 && blockchainResponse.statusCode == 200) {
      dbInstitutions = jsonDecode(dbResponse.body);
      blockchainInstitutions = jsonDecode(blockchainResponse.body);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      body: (dbInstitutions == null || blockchainInstitutions == null)
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 30),
                        child: Text(
                          'DATABASE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Pallete.gradient3,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 100),
                        child: Text(
                          'BLOCKCHAIN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Pallete.gradient3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: dbInstitutions!.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                    itemBuilder: (context, index) {
                      var dbInstitution = dbInstitutions![index];
                      var blockchainInstitution = blockchainInstitutions!
                          .firstWhere(
                              (inst) => inst['id'] == dbInstitution['ID'],
                              orElse: () => {});

                      bool isSame = dbInstitution['username'] ==
                              blockchainInstitution['name'] &&
                          dbInstitution['ID'] == blockchainInstitution['id'];

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${dbInstitution['username']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Pallete.whiteColor,
                                  ),
                                ),
                                Text(
                                  'ID: ${dbInstitution['ID']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Pallete.whiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${blockchainInstitution?['name'] ?? 'No data'}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Pallete.whiteColor,
                                  ),
                                ),
                                Text(
                                  'ID: ${blockchainInstitution['id'] ?? 'No data'}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Pallete.whiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSame)
                                const Padding(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text(
                                    'Verified',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (!isSame)
                                const Padding(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text(
                                    'Not verified',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              Icon(
                                isSame ? Icons.check : Icons.close,
                                color: isSame ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
