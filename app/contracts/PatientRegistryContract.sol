pragma solidity ^0.8.0;

contract PatientRegistryContract {
    struct Patient {
        address patientAddress; // wallet
        uint256 patientID; // hash
        MedicalRecord[] medicalRecords; // all of patient's MRs
        uint256 medicalRecordsCount;
    }

    struct MedicalRecord {
        bytes32 medicalRecordHash;
        string cloudLink;
    }

    event newPatientEvent(address patientAddress, uint256 patientID);
    event newMedicalRecordEvent(bytes32 medicalRecordHash, string cloudLink);
    event showPatientDetailsEvent(Patient patient);

    mapping(uint256 => Patient) allPatients;
    uint256 public pacientCount;

    constructor() {
        pacientCount = 0;
    }

    // on register this will get called
    function newPatient(address _patientAddress) public {
        // Verify that the _patientAddress is not already used
        for (uint i = 0; i < pacientCount; i++) {
            if (allPatients[i].patientAddress == _patientAddress) {
                revert("Patient address is already used");
            }
        }

        uint256 patientID = pacientCount;
        Patient storage p = allPatients[patientID];
        p.patientAddress = _patientAddress;
        p.patientID = patientID;
        p.medicalRecordsCount = 0;
        pacientCount++;

        emit newPatientEvent(_patientAddress, patientID);
    }

    function getPatientDetails(
        uint256 _patientID
    ) public {
        // if patient does not exist, you cannot get patient details
        require(
            allPatients[_patientID].patientAddress != address(0),
            "Invalid patient ID"
        );
        emit showPatientDetailsEvent(allPatients[_patientID]);
    }

    function addMedicalRecordToPatient(
        uint256 patientID,
        bytes32 _medicalRecordID,
        string memory _cloudLink
    ) public {
        // if patient does not exist, you cannot add a medical record to it
        require(
            allPatients[patientID].patientAddress != address(0),
            "Invalid patient ID"
        );

        Patient storage p = allPatients[patientID];
        MedicalRecord memory mr = MedicalRecord({
            medicalRecordHash: _medicalRecordID,
            cloudLink: _cloudLink
        });
        p.medicalRecords.push(mr);
        emit newMedicalRecordEvent(_medicalRecordID, _cloudLink);
    }
}