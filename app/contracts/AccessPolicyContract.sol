// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/@openzeppelin/Ownable.sol";

contract AccessPolicyContract is Ownable {
    struct AccessPolicy {
        mapping(bytes32 => bool) employeeIDToAllowed;
        bytes32[] employeeIDs;
        uint256 employeeCount;
    }

    struct PatientPolicies {
        address owner;
        mapping(bytes32 => AccessPolicy) policies;
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
        bytes32 employeeID
    ) external {
        require(
            allPatientPolicies[patientAddress].owner == msg.sender,
            "Sender is not the owner"
        );
        AccessPolicy storage policy = allPatientPolicies[patientAddress]
            .policies[medicalRecordHash];

        if (policy.employeeIDToAllowed[employeeID] == false) {
            policy.employeeIDToAllowed[employeeID] = true;
            bool isDuplicate = false;
            for (uint i = 0; i < policy.employeeIDs.length; i++) {
                if (policy.employeeIDs[i] == employeeID) {
                    isDuplicate = true;
                    break;
                }
            }
            if (!isDuplicate) {
                policy.employeeIDs.push(employeeID);
                policy.employeeCount++;
            }
        }
    }

    function revokeAccess(
        address patientAddress,
        bytes32 medicalRecordHash,
        bytes32 employeeID
    ) external {
        require(
            allPatientPolicies[patientAddress].owner == msg.sender,
            "Sender is not the owner"
        );
        allPatientPolicies[patientAddress]
            .policies[medicalRecordHash]
            .employeeIDToAllowed[employeeID] = false;
    }

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
    ) public view returns (bytes32[] memory allowedemployeeIDs) {
        AccessPolicy storage policy = allPatientPolicies[patientAddress]
            .policies[medicalRecordHash];
        uint256 count = policy.employeeCount;
        uint256 allowedCount = 0;

        for (uint256 i = 0; i < count; i++) {
            if (policy.employeeIDToAllowed[policy.employeeIDs[i]]) {
                allowedCount++;
            }
        }

        allowedemployeeIDs = new bytes32[](allowedCount);

        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            bytes32 employeeID = policy.employeeIDs[i];

            if (policy.employeeIDToAllowed[employeeID]) {
                allowedemployeeIDs[index] = employeeID;
                index++;
            }
        }

        return (allowedemployeeIDs);
    }
}
