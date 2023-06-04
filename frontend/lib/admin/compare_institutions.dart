import 'package:flutter/material.dart';
import 'package:frontend/common/pallete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    var dbResponse =
        await http.get(Uri.parse('http://localhost:8000/get_db_institutions'));
    var blockchainResponse = await http
        .get(Uri.parse('http://localhost:8000/get_blockchain_institutions'));

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
          : ListView.separated(
              padding: const EdgeInsets.all(15.0),
              itemCount: dbInstitutions!.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
              itemBuilder: (context, index) {
                var dbInstitution = dbInstitutions![index];
                var blockchainInstitution = blockchainInstitutions!.firstWhere(
                    (inst) => inst['id'] == dbInstitution['ID'],
                    orElse: () => {});

                bool isSame = dbInstitution['username'] ==
                        blockchainInstitution['name'] &&
                    dbInstitution['ID'] == blockchainInstitution['id'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 10.0),
                  leading: Text(
                    '[DATABASE] ${dbInstitution['username']}\nID: ${dbInstitution['ID']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Pallete.whiteColor,
                    ),
                  ),
                  title: Text(
                    '[BLOCKCHAIN] ${blockchainInstitution['name']}\nID: ${blockchainInstitution['id']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Pallete.whiteColor,
                    ),
                  ),
                  trailing: Row(
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
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Icon(
                        isSame ? Icons.check : Icons.close,
                        color: isSame ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
