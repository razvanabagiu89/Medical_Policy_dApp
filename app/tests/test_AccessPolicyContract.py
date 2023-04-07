import pytest
from web3.exceptions import ContractLogicError
from scripts.deploy import *
from scripts.utils import *
from random import *

web3 = connect_to_web3_address("http://127.0.0.1:8545")


@pytest.fixture
def access_policy_contract():
    contract_address = deploy(web3, "AccessPolicyContract")
    return get_contract(web3, "AccessPolicyContract", contract_address)


def test_create_policies(access_policy_contract):
    # act
    create_policies(access_policy_contract, patient_1_address, web3)

    # assert
    expected_patient_address = get_patient_owner(
        access_policy_contract, patient_1_address
    )
    assert expected_patient_address == patient_1_address


def test_create_policies_unauthorized(access_policy_contract):
    # arrange
    unauthorized_address = patient_2_address

    # act
    with pytest.raises(ContractLogicError):
        tx_hash = access_policy_contract.functions.createPolicies(
            patient_1_address
        ).transact({"from": unauthorized_address})
        web3.eth.wait_for_transaction_receipt(tx_hash)


def test_grant_access(access_policy_contract):
    # arrange
    create_policies(access_policy_contract, patient_1_address, web3)
    patient_id = 15
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)
    institution_id_bytes = string_to_bytes32(institution_1_id)

    # act
    tx_receipt = grant_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_bytes, web3
    )

    # assert
    assert tx_receipt["status"] == 1
    institution_ids = get_patient_policy_allowed_by_medical_record_hash(
        access_policy_contract, patient_1_address, file_hash
    )
    assert len(institution_ids) == 1
    assert institution_ids[0] == institution_id_bytes


# grant access to a medical record by an unauthorized user
def test_grant_access_unauthorized(access_policy_contract):
    # arrange
    unauthorized_address = patient_2_address
    patient_id = 15
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)
    institution_id_bytes = string_to_bytes32(institution_1_id)

    # assert
    with pytest.raises(ContractLogicError):
        tx_hash = access_policy_contract.functions.grantAccess(
            patient_1_address, file_hash, institution_id_bytes
        ).transact({"from": unauthorized_address})
        web3.eth.wait_for_transaction_receipt(tx_hash)


def test_revoke_access(access_policy_contract):
    # arrange
    create_policies(access_policy_contract, patient_1_address, web3)
    patient_id = 15
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)
    institution_id_bytes = string_to_bytes32(institution_1_id)

    # act
    tx_receipt = revoke_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_bytes, web3
    )

    # assert
    assert tx_receipt["status"] == 1
    institution_ids = get_patient_policy_allowed_by_medical_record_hash(
        access_policy_contract, patient_1_address, file_hash
    )
    assert len(institution_ids) == 0


def test_grant_access_two_institutions(access_policy_contract):
    # arrange
    create_policies(access_policy_contract, patient_1_address, web3)
    patient_id = 15
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)
    institution_id_1_bytes = string_to_bytes32(institution_1_id)
    institution_id_2_bytes = string_to_bytes32(institution_2_id)

    # act
    grant_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_1_bytes, web3
    )
    tx_receipt = grant_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_2_bytes, web3
    )

    # assert
    assert tx_receipt["status"] == 1
    institution_ids = get_patient_policy_allowed_by_medical_record_hash(
        access_policy_contract, patient_1_address, file_hash
    )
    assert len(institution_ids) == 2
    assert institution_ids[0] == institution_id_1_bytes
    assert institution_ids[1] == institution_id_2_bytes


def test_grant_access_three_institutions_revoke_one(access_policy_contract):
    # arrange
    create_policies(access_policy_contract, patient_1_address, web3)
    patient_id = 15
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)
    institution_id_1_bytes = string_to_bytes32(institution_1_id)
    institution_id_2_bytes = string_to_bytes32(institution_2_id)
    institution_id_3_bytes = string_to_bytes32(institution_3_id)

    # act
    grant_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_1_bytes, web3
    )
    grant_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_2_bytes, web3
    )
    grant_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_3_bytes, web3
    )
    tx_receipt = revoke_access(
        access_policy_contract, patient_1_address, file_hash, institution_id_1_bytes, web3
    )

    # assert
    assert tx_receipt["status"] == 1
    institution_ids = get_patient_policy_allowed_by_medical_record_hash(
        access_policy_contract, patient_1_address, file_hash
    )
    assert len(institution_ids) == 2
    assert institution_ids[0] == institution_id_2_bytes
    assert institution_ids[1] == institution_id_3_bytes
