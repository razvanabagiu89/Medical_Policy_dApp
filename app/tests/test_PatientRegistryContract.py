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


web3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
with open("tests/test_config.yaml", "r") as stream:
    yaml_file = safe_load(stream)


# uses admin address as intended for creation of new patient
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


# owner of the contract will be the deployer (admin)
def test_deploy_contract():
    # act
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )

    # assert
    patient_count = patient_registry_contract.functions.patientCount().call()
    expected_patient_count = 0
    assert patient_count == expected_patient_count


# new patient can only be called by the admin - here admin is used to call
def test_new_patient_creation():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    expected_patient_id = 15

    # act
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, expected_patient_id, "patient1"
    )

    # assert
    expected_patient_address = yaml_file["patients"]["patient1"]["address"]

    assert patient_id == expected_patient_id
    assert patient_addresses[0] == expected_patient_address
    assert len(patient_addresses) == 1
    assert len(medical_records_hashes) == 0


# new patient can only be called by the admin - here patient1 is used to call -> should fail
def test_new_patient_by_other_wallet():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Ownable: caller is not the owner",
    ):
        tx_hash = patient_registry_contract.functions.newPatient(
            yaml_file["patients"]["patient1"]["address"], patient_id
        ).transact(
            {"from": yaml_file["patients"]["patient1"]["address"]}
        )  # notice from is patient1
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


"""
# get details on new patient with 1 address and 0 medical records
def test_get_details_new_patient():
    # already tested in test_new_patient_creation
"""


def test_add_medicalrecord_to_non_existing_patient():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Invalid patient ID",
    ):
        tx_hash = patient_registry_contract.functions.addMedicalRecord(
            patient_id, file_hash
        ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_add_medicalrecord():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())

    # act
    tx_hash = patient_registry_contract.functions.addMedicalRecord(
        patient_id, file_hash
    ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
    web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )
    assert medical_records_hashes[0] == file_hash
    assert len(medical_records_hashes) == 1


# should fail
def test_add_medicalrecord_by_other_wallet():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    premade_hash = str(patient_id) + "-" + "demo.pdf"
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Sender is not authorized",
    ):
        tx_hash = patient_registry_contract.functions.addMedicalRecord(
            patient_id, file_hash
        ).transact(
            {"from": yaml_file["patients"]["patient2"]["address"]}
        )  # notice from is patient2
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_add_wallet_to_non_existing_patient():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    expected_new_wallet = yaml_file["patients"]["patient2"]["address"]

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Invalid patient ID",
    ):
        tx_hash = patient_registry_contract.functions.addWallet(
            patient_id, expected_new_wallet
        ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_add_wallet():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    expected_new_wallet = yaml_file["patients"]["patient2"]["address"]

    # act
    tx_hash = patient_registry_contract.functions.addWallet(
        patient_id, expected_new_wallet
    ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
    web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    patient_addresses = patient_registry_contract.functions.getPatientAddresses(
        patient_id
    ).call()
    assert patient_addresses[1] == expected_new_wallet
    assert patient_addresses[0] == yaml_file["patients"]["patient1"]["address"]
    assert len(patient_addresses) == 2


# should fail
def test_add_wallet_by_other_wallet():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    expected_new_wallet = yaml_file["patients"]["patient2"]["address"]

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Sender is not authorized",
    ):
        tx_hash = patient_registry_contract.functions.addWallet(
            patient_id, expected_new_wallet
        ).transact(
            {"from": yaml_file["patients"]["patient2"]["address"]}
        )  # notice from is patient2
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


# should fail
def test_get_patientaddresses_to_non_existing_patient():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15

    # act and assert
    with pytest.raises(
        ValueError,
        match="VM Exception while processing transaction: revert Invalid patient ID",
    ):
        tx_hash = patient_registry_contract.functions.getPatientAddresses(
            patient_id
        ).call()
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_get_medicalrecordshashes_to_non_existing_patient():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15

    # act and assert
    with pytest.raises(
        ValueError,
        match="VM Exception while processing transaction: revert Invalid patient ID",
    ):
        tx_hash = patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


# create a patient with 1 wallet and 3 medical records
def test_simple():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )

    # act
    for i in range(3):
        premade_hash = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())

        tx_hash = patient_registry_contract.functions.addMedicalRecord(
            patient_id, file_hash
        ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
        web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    patient_addresses = patient_registry_contract.functions.getPatientAddresses(
        patient_id
    ).call()
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )

    assert patient_addresses[0] == yaml_file["patients"]["patient1"]["address"]
    assert len(patient_addresses) == 1

    for i in range(3):
        premade_hash = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
        assert medical_records_hashes[i] == file_hash

    assert len(medical_records_hashes) == 3


# create a patient with 2 wallets and add 2 medical records to each wallet
def test_complex():
    # arrange
    contract_address = deploy(web3, "PatientRegistryContract")
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", contract_address
    )
    patient_id = 15
    patient_addresses, patient_id, medical_records_hashes = create_patient(
        patient_registry_contract, patient_id, "patient1"
    )
    expected_new_wallet = yaml_file["patients"]["patient2"]["address"]

    # act
    tx_hash = patient_registry_contract.functions.addWallet(
        patient_id, expected_new_wallet
    ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
    web3.eth.wait_for_transaction_receipt(tx_hash)

    for i in range(2):
        premade_hash = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())

        tx_hash = patient_registry_contract.functions.addMedicalRecord(
            patient_id, file_hash
        ).transact({"from": yaml_file["patients"]["patient1"]["address"]})
        web3.eth.wait_for_transaction_receipt(tx_hash)

        tx_hash = patient_registry_contract.functions.addMedicalRecord(
            patient_id, file_hash
        ).transact({"from": yaml_file["patients"]["patient2"]["address"]})
        web3.eth.wait_for_transaction_receipt(tx_hash)

    # assert
    patient_addresses = patient_registry_contract.functions.getPatientAddresses(
        patient_id
    ).call()
    medical_records_hashes = (
        patient_registry_contract.functions.getPatientMedicalRecordsHashes(
            patient_id
        ).call()
    )

    assert patient_addresses[0] == yaml_file["patients"]["patient1"]["address"]
    assert patient_addresses[1] == yaml_file["patients"]["patient2"]["address"]
    assert len(patient_addresses) == 2

    for i in range(2):
        premade_hash = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())
        assert medical_records_hashes[i * 2] == file_hash
        assert medical_records_hashes[i * 2 + 1] == file_hash

    assert len(medical_records_hashes) == 4
