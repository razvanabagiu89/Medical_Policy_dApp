from web3 import Web3
import os
import sys
from dotenv import load_dotenv
from solcx import compile_source, install_solc
from web3 import Web3

# setup web3
ganache_url = "http://127.0.0.1:8545"
web3 = Web3(Web3.HTTPProvider(ganache_url))
if web3.is_connected():
    print("Connected to ganache-cli")

load_dotenv(".env")
my_address = os.environ.get("MY_ADDRESS")
private_key = os.getenv("PRIVATE_KEY")
chain_id = int(os.getenv("CHAIN_ID"))
contract_name = sys.argv[1]

# install_solc('0.8.0')

with open(f"contracts/{contract_name}.sol", "r") as file:
    source_code = file.read()

compiled_contract = compile_source(
    source=source_code, output_values=["abi", "bin"], solc_version="0.8.0"
)
contract_interface = compiled_contract[f"<stdin>:{contract_name}"]
abi = contract_interface["abi"]
bytecode = contract_interface["bin"]

contract = web3.eth.contract(abi=abi, bytecode=bytecode)
nonce = web3.eth.get_transaction_count(my_address)
transaction = contract.constructor().build_transaction(
    {"chainId": chain_id, "from": my_address, "nonce": nonce}
)
signed_tx = web3.eth.account.sign_transaction(transaction, private_key=private_key)
tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
contract_address = tx_receipt.contractAddress

print("Contract address:", contract_address)
