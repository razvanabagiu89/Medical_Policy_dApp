library utils;

import 'dart:convert';
import 'package:hex/hex.dart';

import 'package:flutter/services.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;

String patientRegistryContractJsonPath =
    'contracts/PatientRegistryContract.json';
String accessPolicyContractJsonPath = 'contracts/AccessPolicyContract.json';
String patientRegistryContractAddress = '';
String accessPolicyContractAddress = '';

Future<void> parseYamlFile() async {
  String yamlString = await rootBundle.loadString('app_config.yaml');
  YamlMap yamlMap = loadYaml(yamlString);

  patientRegistryContractAddress =
      yamlMap["web3"]["patient_registry_contract_address"];
  accessPolicyContractAddress =
      yamlMap["web3"]["access_policy_contract_address"];
}

Future<Contract> getPatientRegistryContract(Signer provider) async {
  final contract = await getContract(
      contractAddress: patientRegistryContractAddress,
      contractJsonPath: patientRegistryContractJsonPath,
      provider: provider);
  return contract;
}

Future<Contract> getAccessPolicyContract(Signer provider) async {
  final contract = await getContract(
      contractAddress: accessPolicyContractAddress,
      contractJsonPath: accessPolicyContractJsonPath,
      provider: provider);
  return contract;
}

Future<Contract> getContract({
  required String contractAddress,
  required String contractJsonPath,
  required Signer provider,
}) async {
  final abiString = await rootBundle.loadString(contractJsonPath);
  final contract = Contract(contractAddress, abiString, provider);
  return contract;
}

Uint8List stringToBytes32(String inputString) {
  List<int> encodedString = utf8.encode(inputString);
  Uint8List bytes32 = Uint8List(32);
  int maxLength = encodedString.length > 32 ? 32 : encodedString.length;
  bytes32.setRange(0, maxLength, encodedString);
  return bytes32;
}

String bytes32ToString(String inputHexString) {
  inputHexString = inputHexString.substring(2);
  Uint8List inputBytes = Uint8List.fromList(HEX.decode(inputHexString));
  String decodedString = utf8.decode(inputBytes);
  return decodedString.trimRight();
}

String computeHash(String filename) {
  DateTime now = DateTime.now();
  String combined = filename + now.toString();
  List<int> bytes = utf8.encode(combined);
  Digest digest = sha256.convert(bytes);

  String hashHexString = HEX.encode(digest.bytes);
  return hashHexString;
}

Uint8List hexStringToUint8List(String hexString) {
  List<int> intList = HEX.decode(hexString);
  return Uint8List.fromList(intList);
}

Future<List<String>> fetchMedicalHashes(doctor_id) async {
  final url = 'http://localhost:5000/api/doctor/$doctor_id/show_documents';
  final response = await http.get(
    Uri.parse(url),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    List<dynamic> accessToList = jsonResponse['access_to'];
    List<String> medicalHashes =
        accessToList.map((hash) => hash.toString()).toList();
    return medicalHashes;
  } else {
    throw Exception('Failed to load medical hashes');
  }
}
