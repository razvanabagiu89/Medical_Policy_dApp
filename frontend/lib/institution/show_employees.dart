import 'package:flutter/material.dart';
import 'package:frontend/common/pallete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../user_provider.dart';

class ShowEmployees extends StatefulWidget {
  @override
  _ShowEmployeesState createState() => _ShowEmployeesState();
}

class _ShowEmployeesState extends State<ShowEmployees> {
  List<dynamic>? employees;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    final userModel = context.read<UserProvider>();
    var response = await http.get(
      Uri.parse('https://localhost:8000/get_employees'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
    );

    if (response.statusCode == 200) {
      employees = jsonDecode(response.body);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      body: (employees == null)
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 0),
                        child: Text(
                          'Name',
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
                        padding: EdgeInsets.only(right: 0),
                        child: Text(
                          'Username',
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
                        padding: EdgeInsets.only(right: 0),
                        child: Text(
                          'ID',
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
                    itemCount: employees!.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                    itemBuilder: (context, index) {
                      var employee = employees![index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${employee['full_name']}',
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
                                  '${employee['username']}',
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
                                  '${employee['ID']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Pallete.whiteColor,
                                  ),
                                ),
                              ],
                            ),
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
