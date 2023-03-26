from brownie import accounts, config, PatientRegistryContract, network
from scripts.helpful_scripts import get_account, get_contract
from hashlib import sha256

def deploy_contract():
    account = get_account()
    PatientRegistryContract.deploy({"from": account})
    
def main():
    deploy_contract()
    account = get_account()
    patient_registry_contract = get_contract("patient_registry_contract")

    """
    patient: 
    patientAddress = account.address
    patientID = 0
    medicalRecordLink1 = "www.demo.com/file1.pdf"
    medicalRecordHash1 = hash(medicalRecordLink1)
    ... etc


    """

    tx = patient_registry_contract.newPatient(account.address)
    tx.wait(1)
    # add patient
    event = patient_registry_contract.events.newPatientEvent().createFilter(fromBlock="latest").get_all_entries()
    patient_ID = event[0]['args']['patientID']
    
    # patientID = 0
    # add medical record 1
    medicalRecordLink1 = "www.demo.com/file1.pdf"
    medicalRecordHash1 = bytes.fromhex(sha256(medicalRecordLink1.encode('utf-8')).hexdigest())

    tx = patient_registry_contract.addMedicalRecordToPatient(patient_ID, medicalRecordHash1, medicalRecordLink1)
    tx.wait(1)
    event = patient_registry_contract.events.newMedicalRecordEvent().createFilter(fromBlock="latest").get_all_entries()
    print(event[0]['args'])

    if (event[0]['args']['medicalRecordHash']) == medicalRecordHash1:
        print("Medical record 1 added successfully")

    # add medical record 2
    medicalRecordLink2 = "www.demo.com/file2.pdf"
    medicalRecordHash2 = bytes.fromhex(sha256(medicalRecordLink2.encode('utf-8')).hexdigest())

    tx = patient_registry_contract.addMedicalRecordToPatient(patient_ID, medicalRecordHash2, medicalRecordLink2)
    tx.wait(1)
    event = patient_registry_contract.events.newMedicalRecordEvent().createFilter(fromBlock="latest").get_all_entries()
    print(event[0]['args'])

    if (event[0]['args']['medicalRecordHash']) == medicalRecordHash2:
        print("Medical record 2 added successfully")

    tx = patient_registry_contract.getPatientDetails(patient_ID)
    tx.wait(1)
    event = patient_registry_contract.events.showPatientDetailsEvent().createFilter(fromBlock="latest").get_all_entries()
    print(event[0]['args'])
