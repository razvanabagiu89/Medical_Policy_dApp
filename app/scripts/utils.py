from web3 import Web3
from yaml import safe_load
from random import *
from hashlib import sha256
from dotenv import load_dotenv
import os
from solcx import compile_source, install_solc
import boto3
import json


def connect_to_web3_address(address):
    web3 = Web3(Web3.HTTPProvider(address))
    return web3


def load_yaml_file(file):
    with open(file, "r") as stream:
        yaml_file = safe_load(stream)
    return yaml_file


########################################## App ##########################################

load_dotenv(".env")
admin_address = os.environ.get("ADMIN_ADDRESS")
admin_private_key = os.getenv("ADMIN_PRIVATE_KEY")
s3_access_key = os.environ.get("ACCESS_KEY")
s3_secret_key = os.environ.get("SECRET_ACCESS_KEY")
s3_bucket_name = "bucket-test-rzw"
s3_region = "eu-west-2"

app_config = load_yaml_file("app_config.yaml")

# web3
web3_host = app_config["web3"]["host"]
chain_id = app_config["web3"]["chain_id"]
patient_registry_contract_address = app_config["web3"][
    "patient_registry_contract_address"
]
access_policy_contract_address = app_config["web3"]["access_policy_contract_address"]

# flask
app_secret_key = app_config["flask"]["secret_key"]

# db
mongodb_host = app_config["mongodb"]["host"]
db_name = app_config["mongodb"]["db_name"]
entities = app_config["mongodb"]["entities_collection"]

########################################## Testing Smart Contracts ##########################################

test_file = load_yaml_file("tests/test_config.yaml")
admin_address = test_file["admin"]["address"]
patient_1_address = test_file["patients"]["patient1"]["address"]
patient_2_address = test_file["patients"]["patient2"]["address"]
patient_3_address = test_file["patients"]["patient3"]["address"]
institution_1_id = test_file["institutions"][0]
institution_2_id = test_file["institutions"][1]
institution_3_id = test_file["institutions"][2]

########################################## Patient Registry Contract ##########################################


def create_patient(
    patient_registry_contract, patient_id, patient_address, web3_instance
):
    tx_hash = patient_registry_contract.functions.newPatient(
        patient_address, patient_id
    ).transact({"from": admin_address})
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt


def get_patient_addresses(patient_registry_contract, patient_id):
    patient_addresses = patient_registry_contract.functions.getPatientAddresses(
        patient_id
    ).call()
    return patient_addresses


def get_patient_medical_records_hashes(patient_registry_contract, patient_id):
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )
    return medical_records_hashes


def get_patient_count(patient_registry_contract):
    patient_count = patient_registry_contract.functions.patientCount().call()
    return patient_count


# deprecated - used only in tests
def compute_hash(filename):
    file_hash = bytes.fromhex(sha256(filename.encode("utf-8")).hexdigest())
    return file_hash


# deprecated - used only in tests
def add_medical_record_to_patient(
    patient_registry_contract, patient_address, patient_id, file_hash, web3_instance
):
    tx_hash = patient_registry_contract.functions.addMedicalRecord(
        patient_id, file_hash
    ).transact({"from": patient_address})
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt


class WalletAddressAlreadyExists(Exception):
    pass


# deprecated - used only in tests
def add_wallet_to_patient(
    patient_registry_contract,
    patient_address,
    new_patient_address,
    patient_id,
    web3_instance,
):
    current_patient_addresses = get_patient_addresses(
        patient_registry_contract, patient_id
    )
    if new_patient_address not in current_patient_addresses:
        tx_hash = patient_registry_contract.functions.addWallet(
            patient_id, new_patient_address
        ).transact({"from": patient_address})
        tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
        return tx_receipt
    else:
        raise WalletAddressAlreadyExists(
            "The new wallet address already exists for this patient."
        )


def check_wallet_exists(
    patient_registry_contract,
    new_patient_address,
    patient_id,
):
    current_patient_addresses = get_patient_addresses(
        patient_registry_contract, patient_id
    )
    if new_patient_address in current_patient_addresses:
        raise WalletAddressAlreadyExists(
            "The new wallet address already exists for this patient."
        )


########################################## AccessPolicyContract ##########################################


def string_to_bytes32(input_string: str):
    return input_string.encode("utf-8").ljust(32, b"\0")


def hex_to_bytes32(input_string: str):
    return Web3.to_bytes(hexstr=input_string).ljust(32, b"\0")


# onlyOwner
def create_policies(access_policy_contract, patient_address, web3_instance):
    tx_hash = access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt


# deprecated - used only in tests
def grant_access(
    access_policy_contract,
    patient_address,
    file_hash,
    institution_id_bytes,
    web3_instance,
):
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt


# deprecated - used only in tests
def revoke_access(
    access_policy_contract,
    patient_address,
    file_hash,
    institution_id_bytes,
    web3_instance,
):
    tx_hash = access_policy_contract.functions.revokeAccess(
        patient_address, file_hash, institution_id_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt


def get_patient_policy_allowed_by_medical_record_hash(
    access_policy_contract, patient_address, file_hash
):
    institution_ids = (
        access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
            patient_address, file_hash
        ).call()
    )
    return institution_ids


def get_patient_owner(access_policy_contract, patient_address):
    patient_owner = access_policy_contract.functions.getPatientOwner(
        patient_address
    ).call()
    return patient_owner


def deploy(web3, contract_name):
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
    signed_tx = web3.eth.account.sign_transaction(
        transaction, private_key=admin_private_key
    )
    tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    contract_address = tx_receipt.contractAddress

    print("Contract address:", contract_address)
    return contract_address


def get_contract(web3, contract_name, contract_address):
    code = web3.eth.get_code(contract_address)

    if code.hex() == "0x":
        print(f"Contract not found at address {contract_address}")
        exit()
    else:
        with open(f"contracts/{contract_name}.sol", "r") as file:
            source_code = file.read()
        compiled_contract = compile_source(
            source=source_code,
            output_values=["abi", "bin"],
            solc_version="0.8.0",
        )
        contract_interface = compiled_contract[f"<stdin>:{contract_name}"]
        abi = contract_interface["abi"]
        abi_json = json.dumps(abi)
        # abi2 = ''.join(abi)
        f = open(f"../frontend/contracts/{contract_name}.abi", "w+")
        f.write(abi_json)
        f.close()

        contract = web3.eth.contract(address=contract_address, abi=abi)

        return contract


def upload_file_to_s3(request, medical_record_hash):
    s3_client = boto3.client(
        "s3",
        region_name=s3_region,
        aws_access_key_id=s3_access_key,
        aws_secret_access_key=s3_secret_key,
    )
    bucket_name = s3_bucket_name
    file_key = f"medical_records/{medical_record_hash}.pdf"
    file_content = request.files[
        "file"
    ].read()  # Assumes the file is sent as a multipart form-data field named "file"
    s3_client.put_object(Bucket=bucket_name, Key=file_key, Body=file_content)
