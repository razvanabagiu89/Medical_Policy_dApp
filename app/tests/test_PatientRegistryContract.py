import pytest
from web3.exceptions import ContractLogicError
from scripts.utils import *
from random import *


web3 = connect_to_web3_address("http://127.0.0.1:8545")


@pytest.fixture
def patient_registry_contract():
    contract_address = deploy(web3, "PatientRegistryContract")
    return get_contract(web3, "PatientRegistryContract", contract_address)


def test_deploy_contract(patient_registry_contract):
    # assert
    patient_count = get_patient_count(patient_registry_contract)
    expected_patient_count = 0
    assert patient_count == expected_patient_count


# new patient can only be called by the admin address
def test_new_patient_creation(patient_registry_contract):
    # arrange
    patient_id = 15

    # act
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)
    patient_addresses = get_patient_addresses(patient_registry_contract, patient_id)
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    # assert
    expected_patient_address = patient_1_address
    assert patient_addresses[0] == expected_patient_address
    assert len(patient_addresses) == 1
    assert len(medical_records_hashes) == 0


# new patient is done only by admin address
def test_new_patient_by_other_wallet(patient_registry_contract):
    # arrange
    patient_id = 15

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Ownable: caller is not the owner",
    ):
        tx_hash = patient_registry_contract.functions.newPatient(
            patient_1_address, patient_id
        ).transact(
            {"from": patient_1_address}
        )  # notice from is patient1
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_add_medicalrecord_to_non_existing_patient(patient_registry_contract):
    # arrange
    patient_id = 15
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Invalid patient ID",
    ):
        tx_receipt = add_medical_record_to_patient(
            patient_registry_contract, patient_1_address, patient_id, file_hash, web3
        )
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_add_medicalrecord(patient_registry_contract):
    # arrange
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)

    # act
    add_medical_record_to_patient(
        patient_registry_contract, patient_1_address, patient_id, file_hash, web3
    )

    # assert
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    assert medical_records_hashes[0] == file_hash
    assert len(medical_records_hashes) == 1


def test_add_medicalrecord_by_other_wallet(patient_registry_contract):
    # arrange
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Sender is not authorized",
    ):
        tx_receipt = add_medical_record_to_patient(
            patient_registry_contract, patient_2_address, patient_id, file_hash, web3
        )  # notice from is patient2
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_add_wallet_to_non_existing_patient(patient_registry_contract):
    # arrange
    patient_id = 15

    # act and assert
    with pytest.raises(
        ValueError,
        match="VM Exception while processing transaction: revert Invalid patient ID",
    ):
        tx_receipt = add_wallet_to_patient(
            patient_registry_contract,
            patient_1_address,
            patient_2_address,
            patient_id,
            web3,
        )
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_add_wallet(patient_registry_contract):
    # arrange
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)
    expected_new_wallet = patient_2_address

    # act
    add_wallet_to_patient(
        patient_registry_contract,
        patient_1_address,
        patient_2_address,
        patient_id,
        web3,
    )

    # assert
    patient_addresses = get_patient_addresses(patient_registry_contract, patient_id)
    assert patient_addresses[0] == patient_1_address
    assert patient_addresses[1] == expected_new_wallet
    assert len(patient_addresses) == 2


def test_add_wallet_by_other_wallet(patient_registry_contract):
    # arrange
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)

    # act and assert
    with pytest.raises(
        ContractLogicError,
        match="execution reverted: VM Exception while processing transaction: revert Sender is not authorized",
    ):
        tx_receipt = add_wallet_to_patient(
            patient_registry_contract,
            patient_2_address,
            patient_2_address,
            patient_id,
            web3,
        )  # notice from is patient2
        assert tx_receipt.status == 0, "Transaction should have reverted"


def test_get_patientaddresses_to_non_existing_patient(patient_registry_contract):
    # arrange
    patient_id = 15

    # act and assert
    with pytest.raises(
        ValueError,
        match="VM Exception while processing transaction: revert Invalid patient ID",
    ):
        get_patient_addresses(patient_registry_contract, patient_id)


def test_get_medicalrecordshashes_to_non_existing_patient(patient_registry_contract):
    # arrange
    patient_id = 15

    # act and assert
    with pytest.raises(
        ValueError,
        match="VM Exception while processing transaction: revert Invalid patient ID",
    ):
        get_patient_medical_records_hashes(patient_registry_contract, patient_id)


# create a patient with 1 wallet and 3 medical records
def test_simple(patient_registry_contract):
    # arrange
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)

    # act
    for i in range(3):
        filename = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = compute_hash(filename)

        add_medical_record_to_patient(
            patient_registry_contract, patient_1_address, patient_id, file_hash, web3
        )

    # assert
    patient_addresses = get_patient_addresses(patient_registry_contract, patient_id)
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    assert patient_addresses[0] == patient_1_address
    assert len(patient_addresses) == 1

    for i in range(3):
        filename = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = compute_hash(filename)
        assert medical_records_hashes[i] == file_hash

    assert len(medical_records_hashes) == 3


# create a patient with 2 wallets and add 2 medical records to each wallet
def test_complex(patient_registry_contract):
    # arrange
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)

    # act
    add_wallet_to_patient(
        patient_registry_contract,
        patient_1_address,
        patient_2_address,
        patient_id,
        web3,
    )

    for i in range(2):
        filename = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = compute_hash(filename)

        add_medical_record_to_patient(
            patient_registry_contract, patient_1_address, patient_id, file_hash, web3
        )

        add_medical_record_to_patient(
            patient_registry_contract, patient_2_address, patient_id, file_hash, web3
        )

    # assert
    patient_addresses = get_patient_addresses(patient_registry_contract, patient_id)
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    assert patient_addresses[0] == patient_1_address
    assert patient_addresses[1] == patient_2_address
    assert len(patient_addresses) == 2

    for i in range(2):
        filename = str(patient_id) + "-" + str(i) + ".pdf"
        file_hash = compute_hash(filename)
        assert medical_records_hashes[i * 2] == file_hash
        assert medical_records_hashes[i * 2 + 1] == file_hash

    assert len(medical_records_hashes) == 4
