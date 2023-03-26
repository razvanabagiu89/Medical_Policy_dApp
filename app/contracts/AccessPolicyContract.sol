pragma solidity ^0.8.0;

contract AccessPolicyContract {
    
    address public owner;
    
    struct AccessPolicy {
        uint256[] institutionIDs;
        bool[] allowed;
    }
    
    mapping(bytes32 => AccessPolicy) policies;
    
    
    modifier onlyOwner() {
        //TBD
        _;
    }
    
    function getAllPolicies(bytes32 _hashMedicalRecord) public view returns (uint256[] memory, bool[] memory) {
        AccessPolicy storage accessPolicy = policies[_hashMedicalRecord];
        return (accessPolicy.institutionIDs, accessPolicy.allowed);
    }
    
    function getAccess(bytes32 _hashMedicalRecord, uint256 _institutionID) public view returns (bool) {
        AccessPolicy storage accessPolicy = policies[_hashMedicalRecord];
        return accessPolicy.allowed[findIndex(accessPolicy.institutionIDs, _institutionID)];
    }
    
    function grantAccess(bytes32 _hashMedicalRecord, uint256 _institutionID) public onlyOwner {
        AccessPolicy storage accessPolicy = policies[_hashMedicalRecord];
        accessPolicy.institutionIDs.push(_institutionID);
        accessPolicy.allowed.push(true);
    }
    
    function revokeAccess(bytes32 _hashMedicalRecord, uint256 _institutionID) public onlyOwner {
        AccessPolicy storage accessPolicy = policies[_hashMedicalRecord];
        uint256 index = findIndex(accessPolicy.institutionIDs, _institutionID);
        for (uint256 i = index; i < accessPolicy.institutionIDs.length - 1; i++) {
            accessPolicy.institutionIDs[i] = accessPolicy.institutionIDs[i+1];
            accessPolicy.allowed[i] = accessPolicy.allowed[i+1];
        }
        accessPolicy.institutionIDs.pop();
        accessPolicy.allowed.pop();
    }
    
    function findIndex(uint256[] memory arr, uint256 val) private pure returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == val) {
                return i;
            }
        }
        revert("Value not found in array.");
    }
}
