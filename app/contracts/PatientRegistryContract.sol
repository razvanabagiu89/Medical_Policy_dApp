// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PatientRegistryContract {
    struct Patient {
        address patientAddress;
        uint256 patientID; // hash or just a number? TBD
        MedicalRecord[] medicalRecords; // all of patient's medical records
        uint256 medicalRecordsCount;
    }

    struct MedicalRecord {
        bytes32 medicalRecordHash;
    }

    event newPatientEvent(address patientAddress, uint256 patientID);
    event newMedicalRecordEvent(bytes32 medicalRecordHash);
    event showPatientDetailsEvent(Patient patient);

    mapping(uint256 => Patient) allPatients;
    uint256 public patientCount;

    constructor() {
        patientCount = 0;
    }

    function newPatient(address _patientAddress) public {
        // TBD
        // Verify that the _patientAddress is not already used
        // for (uint i = 0; i < patientCount; i++) {
        //     if (allPatients[i].patientAddress == _patientAddress) {
        //         revert("Patient address is already used");
        //     }
        // }

        Patient storage p = allPatients[patientCount];
        p.patientAddress = _patientAddress;
        p.patientID = patientCount;
        p.medicalRecordsCount = 0;
        allPatients[patientCount] = p;
        patientCount++;

        emit newPatientEvent(p.patientAddress, p.patientID);
    }

    function getPatientDetails(uint256 _patientID) public {
        // if patient does not exist, you cannot get patient details
        require(
            allPatients[_patientID].patientAddress != address(0),
            "Invalid patient ID"
        );
        emit showPatientDetailsEvent(allPatients[_patientID]);
    }

    function addMedicalRecordToPatient(
        uint256 patientID,
        bytes32 _medicalRecordHash
    ) public {
        // if patient does not exist, you cannot add a medical record to it
        require(
            allPatients[patientID].patientAddress != address(0),
            "Invalid patient ID"
        );

        Patient storage p = allPatients[patientID];
        MedicalRecord memory mr = MedicalRecord({
            medicalRecordHash: _medicalRecordHash
        });
        p.medicalRecords.push(mr);
        p.medicalRecordsCount++;
        emit newMedicalRecordEvent(_medicalRecordHash);
    }
}
