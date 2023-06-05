// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/@openzeppelin/Ownable.sol";

contract PatientRegistryContract is Ownable {
    struct Patient {
        address[] patientAddresses;
        uint256 patientID;
        bytes32[] medicalRecordsHashes;
    }

    mapping(uint256 => Patient) public allPatients;
    uint256 public patientCount;

    constructor() {
        patientCount = 0;
    }

    function newPatient(
        address _patientAddress,
        uint256 _patientID
    ) external onlyOwner {
        Patient storage p = allPatients[_patientID];
        p.patientID = _patientID;
        p.patientAddresses.push(_patientAddress);
        p.medicalRecordsHashes = new bytes32[](0);
        allPatients[_patientID] = p;
        patientCount++;
    }

    function addMedicalRecord(
        uint256 _patientID,
        bytes32 _medicalRecordHash
    ) external {
        require(
            allPatients[_patientID].patientAddresses.length > 0,
            "Invalid patient ID"
        );

        bool senderIsAuthorized = false;
        for (
            uint i = 0;
            i < allPatients[_patientID].patientAddresses.length;
            i++
        ) {
            if (allPatients[_patientID].patientAddresses[i] == msg.sender) {
                senderIsAuthorized = true;
                break;
            }
        }
        require(senderIsAuthorized, "Sender is not authorized");

        Patient storage p = allPatients[_patientID];
        p.medicalRecordsHashes.push(_medicalRecordHash);
    }

    function deleteMedicalRecord(
        uint256 _patientID,
        bytes32 _medicalRecordHash
    ) external {
        require(
            allPatients[_patientID].patientAddresses.length > 0,
            "Invalid patient ID"
        );

        bool senderIsAuthorized = false;
        for (
            uint i = 0;
            i < allPatients[_patientID].patientAddresses.length;
            i++
        ) {
            if (allPatients[_patientID].patientAddresses[i] == msg.sender) {
                senderIsAuthorized = true;
                break;
            }
        }
        require(senderIsAuthorized, "Sender is not authorized");

        uint indexToDelete;
        bool found = false;
        for (
            uint i = 0;
            i < allPatients[_patientID].medicalRecordsHashes.length;
            i++
        ) {
            if (
                allPatients[_patientID].medicalRecordsHashes[i] ==
                _medicalRecordHash
            ) {
                indexToDelete = i;
                found = true;
                break;
            }
        }
        require(found, "Medical record not found");

        allPatients[_patientID].medicalRecordsHashes[
            indexToDelete
        ] = allPatients[_patientID].medicalRecordsHashes[
            allPatients[_patientID].medicalRecordsHashes.length - 1
        ];
        allPatients[_patientID].medicalRecordsHashes.pop();
    }

    function addWallet(uint256 _patientID, address _newAddress) external {
        require(
            allPatients[_patientID].patientAddresses.length > 0,
            "Invalid patient ID"
        );

        bool senderIsInAddresses = false;
        for (
            uint i = 0;
            i < allPatients[_patientID].patientAddresses.length;
            i++
        ) {
            if (allPatients[_patientID].patientAddresses[i] == msg.sender) {
                senderIsInAddresses = true;
                break;
            }
        }

        require(senderIsInAddresses, "Sender is not authorized");

        allPatients[_patientID].patientAddresses.push(_newAddress);
    }

    function getPatientAddresses(
        uint256 _patientID
    ) public view returns (address[] memory) {
        require(
            allPatients[_patientID].patientAddresses.length > 0,
            "Invalid patient ID"
        );
        return allPatients[_patientID].patientAddresses;
    }

    function getPatientMedicalRecordsHashes(
        uint256 _patientID
    ) public view returns (bytes32[] memory) {
        require(
            allPatients[_patientID].patientAddresses.length > 0,
            "Invalid patient ID"
        );
        return allPatients[_patientID].medicalRecordsHashes;
    }
}
