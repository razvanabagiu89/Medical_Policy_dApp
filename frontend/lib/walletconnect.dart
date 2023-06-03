import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WalletConnectProvider wc;
  late Web3Provider web3provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Web3 Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: connectWallet,
          child: Text('Connect Wallet'),
        ),
      ),
    );
  }

  void connectWallet() async {
    wc = WalletConnectProvider.fromRpc(
      {1337: 'http://127.0.0.1:8545'},
      chainId: 1337,
      network: 'private',
    );

    // Enable the session, this will toggle a QRCode Modal
    await wc.connect();

    // Use in Ethers Web3Provider
    web3provider = Web3Provider.fromWalletConnect(wc);

    // You can now use the web3provider to interact with the blockchain
    var gasPrice = await web3provider.getGasPrice();
    print('Gas price: $gasPrice');
  }
}
