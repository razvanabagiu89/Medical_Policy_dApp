// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessPolicyContract {
    struct AccessPolicy {
        mapping(uint256 => bool) institutionIDToAllowed;
    }

    struct PatientPolicies {
        address owner;
        mapping(bytes32 => AccessPolicy) policies; // bytes32 = hash of medical record
    }

    // address of patient (owner above)
    mapping(address => PatientPolicies) patientPolicies;

    function addPolicy(
        address patient,
        bytes32 medicalRecordHash,
        uint256 institutionID
    ) public {
        require(
            msg.sender == patientPolicies[patient].owner,
            "Only patient can add policy."
        );
        patientPolicies[patient]
            .policies[medicalRecordHash]
            .institutionIDToAllowed[institutionID] = true;
    }

    function removePolicy(
        address patient,
        bytes32 medicalRecordHash,
        uint256 institutionID
    ) public {
        require(
            msg.sender == patientPolicies[patient].owner,
            "Only patient can remove policy."
        );
        patientPolicies[patient]
            .policies[medicalRecordHash]
            .institutionIDToAllowed[institutionID] = false;
    }

    function isAllowed(
        address patient,
        bytes32 medicalRecordHash,
        uint256 institutionID
    ) public view returns (bool) {
        return
            patientPolicies[patient]
                .policies[medicalRecordHash]
                .institutionIDToAllowed[institutionID];
    }
}
