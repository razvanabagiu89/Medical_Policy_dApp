// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/@openzeppelin/Ownable.sol";

contract AccessPolicyContract is Ownable {
    struct AccessPolicy {
        mapping(bytes32 => bool) institutionIDToAllowed;
        bytes32[] institutionIDs;
        uint256 institutionCount;
    }

    struct PatientPolicies {
        address owner;
        mapping(bytes32 => AccessPolicy) policies; // (hash of medical record => AccessPolicy)
    }

    mapping(address => PatientPolicies) public allPatientPolicies;

    function createPolicies(address patientAddress) external onlyOwner {
        require(
            allPatientPolicies[patientAddress].owner == address(0),
            "Policies for this patient already exist"
        );
        allPatientPolicies[patientAddress].owner = patientAddress;
    }

    function grantAccess(
        address patientAddress,
        bytes32 medicalRecordHash,
        bytes32 institutionID
    ) external {
        require(
            allPatientPolicies[patientAddress].owner == msg.sender,
            "Sender is not the owner"
        );
        AccessPolicy storage policy = allPatientPolicies[patientAddress]
            .policies[medicalRecordHash];

        if (policy.institutionIDToAllowed[institutionID] == false) {
            policy.institutionIDToAllowed[institutionID] = true;
            policy.institutionIDs.push(institutionID);
            policy.institutionCount++;
        }
    }

    function revokeAccess(
        address patientAddress,
        bytes32 medicalRecordHash,
        bytes32 institutionID
    ) external {
        require(
            allPatientPolicies[patientAddress].owner == msg.sender,
            "Sender is not the owner"
        );
        allPatientPolicies[patientAddress]
            .policies[medicalRecordHash]
            .institutionIDToAllowed[institutionID] = false;
    }

    // Getter functions
    function getPatientOwner(
        address patient_address
    ) public view returns (address) {
        address owner = allPatientPolicies[patient_address].owner;
        require(owner != address(0), "No owner found for this patient address");
        return owner;
    }

    function getPatientPolicyAllowedByMedicalRecordHash(
        address patientAddress,
        bytes32 medicalRecordHash
    ) public view returns (bytes32[] memory allowedInstitutionIDs) {
        AccessPolicy storage policy = allPatientPolicies[patientAddress]
            .policies[medicalRecordHash];
        uint256 count = policy.institutionCount;
        uint256 allowedCount = 0;

        for (uint256 i = 0; i < count; i++) {
            if (policy.institutionIDToAllowed[policy.institutionIDs[i]]) {
                allowedCount++;
            }
        }

        allowedInstitutionIDs = new bytes32[](allowedCount);

        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            bytes32 institutionID = policy.institutionIDs[i];

            if (policy.institutionIDToAllowed[institutionID]) {
                allowedInstitutionIDs[index] = institutionID;
                index++;
            }
        }

        return (allowedInstitutionIDs);
    }
}
