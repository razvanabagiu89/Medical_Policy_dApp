import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'utils.dart';

class MetaMaskProvider extends ChangeNotifier {
  static const operatingChain = goerliChainId; // or ganacheChainId;
  String currentAddress = "";
  int currentChain = -1;
  bool get isEnabled => ethereum != null;
  bool get isInOperatingChain => currentChain == operatingChain;
  bool get isConnected =>
      isEnabled && currentAddress.isNotEmpty && isInOperatingChain;

  Future<void> connect() async {
    if (isEnabled) {
      try {
        final accounts = await ethereum!.requestAccount();
        if (accounts.isEmpty) {
          return;
        }
        accounts;
        currentAddress = accounts.first;
        currentChain = await ethereum!.getChainId();
        notifyListeners();
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> disconnect() async {
    if (isEnabled) {
      try {
        await ethereum!.requestAccount();
        reset();
      } catch (e) {
        print(e);
      }
    }
  }

  reset() {
    currentAddress = "";
    currentChain = -1;
    notifyListeners();
  }

  start() {
    if (isEnabled) {
      ethereum!.onAccountsChanged((accounts) {
        reset();
      });
      ethereum!.onChainChanged((accounts) {
        reset();
      });
    }
  }
}
