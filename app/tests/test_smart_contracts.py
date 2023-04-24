import pytest
from scripts.utils import *
from random import *

web3 = connect_to_web3_address("http://127.0.0.1:8545")


@pytest.fixture
def deploy_contracts():
    patient_registry_contract_address = deploy(web3, "PatientRegistryContract")
    access_policy_contract_address = deploy(web3, "AccessPolicyContract")
    access_policy_contract = get_contract(
        web3, "AccessPolicyContract", access_policy_contract_address
    )
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", patient_registry_contract_address
    )
    return patient_registry_contract, access_policy_contract


"""
- new patient
- adds 2 different medical records
- grants access to both to two different institutions

"""


def test_simple_1(deploy_contracts):
    # arrange
    patient_registry_contract, access_policy_contract = deploy_contracts
    institution_id_bytes_1 = string_to_bytes32(institution_1_id)
    institution_id_bytes_2 = string_to_bytes32(institution_2_id)

    # act
    # 1. add patient
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)

    # 2. add two medical records
    for i in range(2):
        filename = str(patient_id) + "-" + "demo" + str(i) + ".pdf"
        file_hash = compute_hash(filename)
        add_medical_record_to_patient(
            patient_registry_contract, patient_1_address, patient_id, file_hash, web3
        )

    # 3. create policies
    create_policies(access_policy_contract, patient_1_address, web3)

    # 4. fetch medical records from patient registry contract
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    # 5. grant access for two institutions on every medical record
    for i in range(2):
        grant_access(
            access_policy_contract,
            patient_1_address,
            medical_records_hashes[i],
            institution_id_bytes_1,
            web3,
        )
        grant_access(
            access_policy_contract,
            patient_1_address,
            medical_records_hashes[i],
            institution_id_bytes_2,
            web3,
        )

    # assert
    for i in range(2):
        institution_ids = get_patient_policy_allowed_by_medical_record_hash(
            access_policy_contract, patient_1_address, medical_records_hashes[i]
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
    patient_registry_contract, access_policy_contract = deploy_contracts
    institution_id_bytes_1 = string_to_bytes32(institution_1_id)
    institution_id_bytes_2 = string_to_bytes32(institution_2_id)

    # act
    # 1. add patient
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)

    # 2. add two medical records
    for i in range(2):
        filename = str(patient_id) + "-" + "demo" + str(i) + ".pdf"
        file_hash = compute_hash(filename)
        add_medical_record_to_patient(
            patient_registry_contract, patient_1_address, patient_id, file_hash, web3
        )

    # 3. create policies
    create_policies(access_policy_contract, patient_1_address, web3)

    # 4. fetch medical records from patient registry contract
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    # 5. grant access for two institutions on every medical record
    for i in range(2):
        grant_access(
            access_policy_contract,
            patient_1_address,
            medical_records_hashes[i],
            institution_id_bytes_1,
            web3,
        )
        grant_access(
            access_policy_contract,
            patient_1_address,
            medical_records_hashes[i],
            institution_id_bytes_2,
            web3,
        )

    # 6. revoke access for first institution on the first medical record
    institution_ids = get_patient_policy_allowed_by_medical_record_hash(
        access_policy_contract, patient_1_address, medical_records_hashes[0]
    )
    revoke_access(
        access_policy_contract,
        patient_1_address,
        medical_records_hashes[0],
        institution_ids[0],
        web3,
    )

    # assert
    for i in range(2):
        institution_ids = get_patient_policy_allowed_by_medical_record_hash(
            access_policy_contract, patient_1_address, medical_records_hashes[i]
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
    patient_registry_contract, access_policy_contract = deploy_contracts

    # act
    # 1. add patient
    patient_id = 15
    create_patient(patient_registry_contract, patient_id, patient_1_address, web3)

    # 2. add one medical record
    filename = str(patient_id) + "-" + "demo.pdf"
    file_hash = compute_hash(filename)
    add_medical_record_to_patient(
        patient_registry_contract, patient_1_address, patient_id, file_hash, web3
    )

    # 3. create policies
    create_policies(access_policy_contract, patient_1_address, web3)

    # 4. fetch medical records from patient registry contract
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    # 5. grant access for three institutions on the medical record
    for i in range(3):
        institution_id_bytes = string_to_bytes32(test_file["institutions"][i])
        grant_access(
            access_policy_contract,
            patient_1_address,
            medical_records_hashes[0],
            institution_id_bytes,
            web3,
        )

    # 6. patient adds another wallet
    add_wallet_to_patient(
        patient_registry_contract,
        patient_1_address,
        patient_2_address,
        patient_id,
        web3,
    )

    # 7. add another medical record on the 2nd address
    filename = str(patient_id) + "-" + "demo2.pdf"
    file_hash = compute_hash(filename)
    add_medical_record_to_patient(
        patient_registry_contract, patient_2_address, patient_id, file_hash, web3
    )

    # 8. create policies for this new address
    create_policies(access_policy_contract, patient_2_address, web3)

    # 9. fetch medical records from patient registry contract again
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )

    # 10. grant access for two institutions on the medical record
    for i in range(2):
        institution_id_bytes = string_to_bytes32(test_file["institutions"][i])
        grant_access(
            access_policy_contract,
            patient_2_address,
            medical_records_hashes[0],
            institution_id_bytes,
            web3,
        )

    # assert
    # fetch medical records = first address (1) + second address (1) = 2
    medical_records_hashes = get_patient_medical_records_hashes(
        patient_registry_contract, patient_id
    )
    assert len(medical_records_hashes) == 2

    # fetch addresses = first address (1) + second address (1) = 2
    patient_addresses = get_patient_addresses(patient_registry_contract, patient_id)
    assert len(patient_addresses) == 2
    assert patient_addresses[0] == patient_1_address
    assert patient_addresses[1] == patient_2_address

    # fetch policies for first address
    institution_ids = get_patient_policy_allowed_by_medical_record_hash(
        access_policy_contract, patient_1_address, medical_records_hashes[0]
    )
    assert len(institution_ids) == 3
    for i in range(3):
        institution_id_bytes = string_to_bytes32(test_file["institutions"][i])
        assert institution_ids[i] == institution_id_bytes

    # fetch policies for second address
    institution_ids = get_patient_policy_allowed_by_medical_record_hash(
        access_policy_contract, patient_2_address, medical_records_hashes[0]
    )
    assert len(institution_ids) == 2
    for i in range(2):
        institution_id_bytes = string_to_bytes32(test_file["institutions"][i])
        assert institution_ids[i] == institution_id_bytes
