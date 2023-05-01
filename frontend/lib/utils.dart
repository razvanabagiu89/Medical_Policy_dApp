library utils;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hex/hex.dart';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:crypto/crypto.dart';

String patientRegistryContractAddress =
    '0xEDE52DF912A549dfB0DFb828e4A77CF5d6f4953c';
String patientRegistryContractJsonPath =
    'contracts/PatientRegistryContract.json';
String accessPolicyContractAddress =
    '0xe4B121cB7F3dA058C6522f34e0b80244fC663997';
String accessPolicyContractJsonPath = 'contracts/AccessPolicyContract.json';

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

// Uint8List stringToBytes32(String str) {
//   List<int> bytes = utf8.encode(str);
//   if (bytes.length > 32) {
//     throw ArgumentError('String is too long to fit into bytes32.');
//   }

//   Uint8List paddedBytes = Uint8List(32);
//   paddedBytes.setRange(0, bytes.length, bytes);
//   return paddedBytes;
// }

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

// not tested - bytes 32 hex to string
String bytes32HexToString(Uint8List bytes32) {
  final hexString = HEX.encode(bytes32);
  final codeUnits = hexString.codeUnits;
  return String.fromCharCodes(codeUnits);
}
