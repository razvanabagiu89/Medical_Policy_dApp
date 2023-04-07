import pytest
from web3 import Web3
from web3.exceptions import ContractLogicError
from scripts.deploy import deploy
from scripts.help import get_contract
import sys
from pathlib import Path
from yaml import safe_load
from random import *
from hashlib import sha256

sys.path.append(str(Path(__file__).parent.parent.resolve()))

web3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
with open("tests/test_config.yaml", "r") as stream:
    yaml_file = safe_load(stream)


# fixture to set up the contract
@pytest.fixture
def deploy_contracts():
    contract_address_1 = deploy(web3, "AccessPolicyContract")
    contract_address_2 = deploy(web3, "PatientRegistryContract")

    return get_contract(web3, "AccessPolicyContract", contract_address_1), get_contract(
        web3, "PatientRegistryContract", contract_address_2
    )


def string_to_bytes32(input_string: str) -> bytes:
    return input_string.encode("utf-8").ljust(32, b"\0")


def create_patient(patient_registry_contract, patient_id, patient_name):
    tx_hash = patient_registry_contract.functions.newPatient(
        yaml_file["patients"][patient_name]["address"], patient_id
    ).transact({"from": yaml_file["admin"]["address"]})
    web3.eth.wait_for_transaction_receipt(tx_hash)

    patient_addresses = patient_registry_contract.functions.getPatientAddresses(
        patient_id
    ).call()
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )

    return patient_addresses, patient_id, medical_records_hashes


"""
- new patient
- adds 2 different medical records
- grants access to both to two different institutions

"""


def test_simple_1(deploy_contracts):
    # arrange
    access_policy_contract, patient_registry_contract = deploy_contracts

    # act
    # add patient
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    patient_address = patient_addresses[0]

    # add two medical records
    for i in range(2):
        premade_hash = str(patient_id) + "-" + "demo" + str(i) + ".pdf"
        file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
        tx_hash = patient_registry_contract.functions.addMedicalRecord(
            patient_id, file_hash
        ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
        web3.eth.wait_for_transaction_receipt(tx_hash)

    # create policies
    admin_address = yaml_file["admin"]["address"]
    tx_hash = access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # fetch medical records from patient registry contract
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )
    # grant access for two institutions on every medical record
    for i in range(2):
        institution_id_bytes_1 = string_to_bytes32(yaml_file["institutions"][0])
        institution_id_bytes_2 = string_to_bytes32(yaml_file["institutions"][1])
        # grant to first institution
        tx_hash = access_policy_contract.functions.grantAccess(
            patient_address, medical_records_hashes[i], institution_id_bytes_1
        ).transact({"from": patient_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        # grant to second institution
        tx_hash = access_policy_contract.functions.grantAccess(
            patient_address, medical_records_hashes[i], institution_id_bytes_2
        ).transact({"from": patient_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    for i in range(2):
        institution_id_bytes_1 = string_to_bytes32(yaml_file["institutions"][0])
        institution_id_bytes_2 = string_to_bytes32(yaml_file["institutions"][1])
        institution_ids = (
            access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
                patient_address, medical_records_hashes[i]
            ).call()
        )
        assert len(institution_ids) == 2
        assert institution_ids[0] == institution_id_bytes_1
        assert institution_ids[1] == institution_id_bytes_2


"""
- new patient
- adds 2 different medical records
- grants access to both to two different institutions
- revokes access to one institution on one medical record
"""


def test_simple_2(deploy_contracts):
    # arrange
    access_policy_contract, patient_registry_contract = deploy_contracts

    # act
    # add patient
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    patient_address = patient_addresses[0]

    # add two medical records
    for i in range(2):
        premade_hash = str(patient_id) + "-" + "demo" + str(i) + ".pdf"
        file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
        tx_hash = patient_registry_contract.functions.addMedicalRecord(
            patient_id, file_hash
        ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
        web3.eth.wait_for_transaction_receipt(tx_hash)

    # create policies
    admin_address = yaml_file["admin"]["address"]
    tx_hash = access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # fetch medical records from patient registry contract
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )
    # grant access for two institutions on every medical record
    for i in range(2):
        institution_id_bytes_1 = string_to_bytes32(yaml_file["institutions"][0])
        institution_id_bytes_2 = string_to_bytes32(yaml_file["institutions"][1])
        # grant to first institution
        tx_hash = access_policy_contract.functions.grantAccess(
            patient_address, medical_records_hashes[i], institution_id_bytes_1
        ).transact({"from": patient_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        # grant to second institution
        tx_hash = access_policy_contract.functions.grantAccess(
            patient_address, medical_records_hashes[i], institution_id_bytes_2
        ).transact({"from": patient_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # revoke access for first institution on the first medical record
    # another method: fetch institution id bytes from the contract
    institution_ids = (
        access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
            patient_address, medical_records_hashes[i]
        ).call()
    )
    tx_hash = access_policy_contract.functions.revokeAccess(
        patient_address, medical_records_hashes[0], institution_ids[0]
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    for i in range(2):
        institution_id_bytes_1 = string_to_bytes32(yaml_file["institutions"][0])
        institution_id_bytes_2 = string_to_bytes32(yaml_file["institutions"][1])
        institution_ids = (
            access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
                patient_address, medical_records_hashes[i]
            ).call()
        )
        # for first medical record, only second institution should be allowed
        if i == 0:
            assert len(institution_ids) == 1
            assert institution_ids[0] == institution_id_bytes_2
        else:
            assert len(institution_ids) == 2
            assert institution_ids[0] == institution_id_bytes_1
            assert institution_ids[1] == institution_id_bytes_2


"""
- new patient
- adds 1 medical record
- grants access to three different institutions
- adds another wallet
- adds 1 medical record
- grants access to two different institutions
"""


def test_simple_3(deploy_contracts):
    # arrange
    access_policy_contract, patient_registry_contract = deploy_contracts

    # act
    # add patient
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    patient_address = patient_addresses[0]

    # add one medical record
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
    tx_hash = patient_registry_contract.functions.addMedicalRecord(
        patient_id, file_hash
    ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
    web3.eth.wait_for_transaction_receipt(tx_hash)

    # create policies
    admin_address = yaml_file["admin"]["address"]
    tx_hash = access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # fetch medical records from patient registry contract
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )
    # grant access for three institutions on the medical record
    for i in range(3):
        institution_id_bytes = string_to_bytes32(yaml_file["institutions"][i])
        tx_hash = access_policy_contract.functions.grantAccess(
            patient_address, medical_records_hashes[0], institution_id_bytes
        ).transact({"from": patient_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # patient adds another wallet
    new_patient_address = yaml_file["patients"]["patient2"]["address"]
    tx_hash = patient_registry_contract.functions.addWallet(
        patient_id, new_patient_address
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # add another medical record on the 2nd address
    premade_hash = str(patient_id) + "-" + "demo2.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
    tx_hash = patient_registry_contract.functions.addMedicalRecord(
        patient_id, file_hash).transact({"from": new_patient_address})
    web3.eth.wait_for_transaction_receipt(tx_hash)

    # create policies for this new address
    tx_hash = access_policy_contract.functions.createPolicies(new_patient_address).transact(
        {"from": admin_address}
    )
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # fetch medical records from patient registry contract again
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )
    first_medical_records_hash = medical_records_hashes[0]
    second_medical_records_hash = medical_records_hashes[1]
    # grant access for two institutions on the medical record
    for i in range(2):
        institution_id_bytes = string_to_bytes32(yaml_file["institutions"][i])
        tx_hash = access_policy_contract.functions.grantAccess(
            new_patient_address, second_medical_records_hash, institution_id_bytes
        ).transact({"from": new_patient_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    # fetch medical records = first address (1) + second address (1) = 2
    medical_records_hashes = patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    assert len(medical_records_hashes) == 2
    print(first_medical_records_hash)
    print(second_medical_records_hash)
    # fetch addresses = first address (1) + second address (1) = 2
    patient_addresses = patient_registry_contract.functions.getPatientAddresses(
        patient_id
    ).call()
    assert len(patient_addresses) == 2
    assert patient_addresses[0] == patient_address
    assert patient_addresses[1] == new_patient_address
    # fetch policies for first address
    institution_ids = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
            patient_address, first_medical_records_hash
        ).call()
    assert len(institution_ids) == 3
    for i in range(3):
        institution_id_bytes = string_to_bytes32(yaml_file["institutions"][i])
        assert institution_ids[i] == institution_id_bytes
    # fetch policies for second address
    institution_ids = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
            new_patient_address, second_medical_records_hash
        ).call()
    assert len(institution_ids) == 2
    for i in range(2):
        institution_id_bytes = string_to_bytes32(yaml_file["institutions"][i])
        assert institution_ids[i] == institution_id_bytes


"""
- given test_simple_3
- patient has only patient id
- wants all info:
    - addresses
    - medical records
    - policies
"""

def test_simple_4(deploy_contracts):
    # arrange
    access_policy_contract, patient_registry_contract = deploy_contracts

    # act
    patient_id = 15
    test_simple_3(deploy_contracts)
    # get all info
    patient_addresses = patient_registry_contract.functions.getPatientAddresses(
        patient_id
    ).call()
    print(patient_addresses) # 2
    medical_records_hashes = patient_registry_contract.functions.getPatientMedicalRecordsHashes(
        patient_id
    ).call()
    print(medical_records_hashes) # 2

    # assert
    assert len(patient_addresses) == 2   
    assert len(medical_records_hashes) == 2

    # fetch policies for first address
    institution_ids = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
            patient_addresses[0], medical_records_hashes[0]
        ).call()
    print(institution_ids) # 3
    assert len(institution_ids) == 3
    for i in range(3):
        institution_id_bytes = string_to_bytes32(yaml_file["institutions"][i])
        assert institution_ids[i] == institution_id_bytes
    # fetch policies for second address
    institution_ids = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
            patient_addresses[1], medical_records_hashes[1]
        ).call()
    print(institution_ids) # 2
    assert len(institution_ids) == 2
    for i in range(2):
        institution_id_bytes = string_to_bytes32(yaml_file["institutions"][i])
        assert institution_ids[i] == institution_id_bytes

    

