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
def access_policy_contract():
    contract_address = deploy(web3, "AccessPolicyContract")
    return get_contract(web3, "AccessPolicyContract", contract_address)


def string_to_bytes32(input_string: str) -> bytes:
    return input_string.encode("utf-8").ljust(32, b"\0")


# create policies for a patient
def test_create_policies(access_policy_contract):
    # arrange
    patient_address = yaml_file["patients"]["patient1"]["address"]
    admin_address = yaml_file["admin"]["address"]

    # act
    tx_hash = access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    expected_patient_address = access_policy_contract.functions.getPatientOwner(
        patient_address
    ).call()
    assert tx_receipt["status"] == 1
    assert expected_patient_address == patient_address


# create policies for a patient by an unauthorized user
def test_create_policies_unauthorized(access_policy_contract):
    # arrange
    patient_address = yaml_file["patients"]["patient1"]["address"]
    unauthorized_address = yaml_file["patients"]["patient2"]["address"]

    # act
    with pytest.raises(ContractLogicError):
        tx_hash = access_policy_contract.functions.createPolicies(
            patient_address
        ).transact({"from": unauthorized_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)


# grant access to a medical record
def test_grant_access(access_policy_contract):
    # arrange
    patient_address = yaml_file["patients"]["patient1"]["address"]
    institution_id = yaml_file["institutions"][0]  # RM
    admin_address = yaml_file["admin"]["address"]
    access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    patient_id = 15
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
    institution_id_bytes = string_to_bytes32(institution_id)

    # act
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    assert tx_receipt["status"] == 1
    (
        institution_ids
    ) = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
        patient_address, file_hash
    ).call()
    assert len(institution_ids) == 1
    assert institution_ids[0] == institution_id_bytes


# grant access to a medical record by an unauthorized user
def test_grant_access_unauthorized(access_policy_contract):
    # arrange
    patient_address = yaml_file["patients"]["patient1"]["address"]
    institution_id = yaml_file["institutions"][0]  # RM
    unauthorized_address = yaml_file["patients"]["patient2"]["address"]
    patient_id = 15
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
    institution_id_bytes = string_to_bytes32(institution_id)

    # act
    with pytest.raises(ContractLogicError):
        tx_hash = access_policy_contract.functions.grantAccess(
            patient_address, file_hash, institution_id_bytes
        ).transact({"from": unauthorized_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)


# revoke access to a medical record
def test_revoke_access(access_policy_contract):
    # arrange
    patient_address = yaml_file["patients"]["patient1"]["address"]
    institution_id = yaml_file["institutions"][0]  # RM
    admin_address = yaml_file["admin"]["address"]
    access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    patient_id = 15
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
    institution_id_bytes = string_to_bytes32(institution_id)

    # act
    tx_hash = access_policy_contract.functions.revokeAccess(
        patient_address, file_hash, institution_id_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    assert tx_receipt["status"] == 1
    (
        institution_ids
    ) = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
        patient_address, file_hash
    ).call()
    assert len(institution_ids) == 0


# grant access to two institutions
def test_grant_access_two_institutions(access_policy_contract):
    # arrange
    patient_address = yaml_file["patients"]["patient1"]["address"]
    institution_id_1 = yaml_file["institutions"][0]  # RM
    institution_id_2 = yaml_file["institutions"][1]  # SND
    admin_address = yaml_file["admin"]["address"]
    access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    patient_id = 15
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
    institution_id_1_bytes = string_to_bytes32(institution_id_1)
    institution_id_2_bytes = string_to_bytes32(institution_id_2)

    # act
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_1_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_2_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    assert tx_receipt["status"] == 1
    (
        institution_ids
    ) = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
        patient_address, file_hash
    ).call()
    assert len(institution_ids) == 2
    assert institution_ids[0] == institution_id_1_bytes
    assert institution_ids[1] == institution_id_2_bytes


# grant access to 3 institutions and revoke access to 1
def test_grant_access_three_institutions_revoke_one(access_policy_contract):
    # arrange
    patient_address = yaml_file["patients"]["patient1"]["address"]
    institution_id_1 = yaml_file["institutions"][0]  # RM
    institution_id_2 = yaml_file["institutions"][1]  # SND
    institution_id_3 = yaml_file["institutions"][2]  # ML
    admin_address = yaml_file["admin"]["address"]
    access_policy_contract.functions.createPolicies(patient_address).transact(
        {"from": admin_address}
    )
    patient_id = 15
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
    institution_id_1_bytes = string_to_bytes32(institution_id_1)
    institution_id_2_bytes = string_to_bytes32(institution_id_2)
    institution_id_3_bytes = string_to_bytes32(institution_id_3)

    # act
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_1_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_2_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    tx_hash = access_policy_contract.functions.grantAccess(
        patient_address, file_hash, institution_id_3_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    tx_hash = access_policy_contract.functions.revokeAccess(
        patient_address, file_hash, institution_id_1_bytes
    ).transact({"from": patient_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    assert tx_receipt["status"] == 1
    (
        institution_ids
    ) = access_policy_contract.functions.getPatientPolicyAllowedByMedicalRecordHash(
        patient_address, file_hash
    ).call()
    assert len(institution_ids) == 2
    assert institution_ids[0] == institution_id_2_bytes
    assert institution_ids[1] == institution_id_3_bytes
