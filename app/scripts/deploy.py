import os
import sys
from dotenv import load_dotenv
from solcx import compile_source, install_solc

def deploy(web3, contract_name):

    load_dotenv(".env")
    admin_address = os.environ.get("ADMIN_ADDRESS")
    admin_private_key = os.getenv("ADMIN_PRIVATE_KEY")
    chain_id = int(os.getenv("CHAIN_ID"))

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
    nonce = web3.eth.get_transaction_count(admin_address)
    transaction = contract.constructor().build_transaction(
        {"chainId": chain_id, "from": admin_address, "nonce": nonce}
    )
    signed_tx = web3.eth.account.sign_transaction(transaction, private_key=admin_private_key)
    tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    contract_address = tx_receipt.contractAddress

    print("Contract address:", contract_address)
    return contract_address
