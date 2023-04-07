from web3 import Web3
from yaml import safe_load
from random import *
from hashlib import sha256


def connect_to_web3_address(address):
    web3 = Web3(Web3.HTTPProvider(address))
    return web3


def load_yaml_file(file):
    with open(file, "r") as stream:
        yaml_file = safe_load(stream)
    return yaml_file

yaml_file = load_yaml_file("tests/test_config.yaml")
admin_address = yaml_file["admin"]["address"]
patient_1_address = yaml_file["patients"]["patient1"]["address"]
patient_2_address = yaml_file["patients"]["patient2"]["address"]
patient_3_address = yaml_file["patients"]["patient3"]["address"]
institution_1_id = yaml_file["institutions"][0]
institution_2_id = yaml_file["institutions"][1]
institution_3_id = yaml_file["institutions"][2]

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


def compute_hash(filename):
    file_hash = bytes.fromhex(sha256(filename.encode("utf-8")).hexdigest())
    return file_hash


def add_medical_record_to_patient(
    patient_registry_contract,
    patient_address,
    patient_id,
    file_hash,
    web3_instance
):
    tx_hash = patient_registry_contract.functions.addMedicalRecord(
        patient_id, file_hash
    ).transact({"from": patient_address})
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt


def add_wallet_to_patient(
    patient_registry_contract,
    patient_address,
    new_patient_address,
    patient_id,
    web3_instance
):
    tx_hash = patient_registry_contract.functions.addWallet(
        patient_id, new_patient_address
    ).transact({"from": patient_address})
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt

########################################## AccessPolicyContract ##########################################

def string_to_bytes32(input_string: str) -> bytes:
    return input_string.encode("utf-8").ljust(32, b"\0")


def create_policies(access_policy_contract, patient_address, web3_instance):
    tx_hash = access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt


def grant_access(
    access_policy_contract, patient_address, file_hash, institution_id_bytes, web3_instance
):
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3_instance.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt

def revoke_access(
    access_policy_contract, patient_address, file_hash, institution_id_bytes, web3_instance
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