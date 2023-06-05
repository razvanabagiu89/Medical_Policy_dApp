// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/@openzeppelin/Ownable.sol";

contract InstitutionRegistryContract is Ownable {
    struct Institution {
        bytes32 name;
        uint id;
    }

    Institution[] public institutions;

    function addInstitution(bytes32 name, uint id) public onlyOwner {
        institutions.push(Institution({name: name, id: id}));
    }

    function deleteInstitution(uint id) public onlyOwner {
        for (uint i = 0; i < institutions.length; i++) {
            if (institutions[i].id == id) {
                for (uint j = i; j < institutions.length - 1; j++) {
                    institutions[j] = institutions[j + 1];
                }
                institutions.pop();
                break;
            }
        }
    }

    function getInstitutionCount() public view returns (uint256) {
        return institutions.length;
    }

    function getInstitutionById(
        uint index
    ) public view returns (bytes32, uint) {
        return (institutions[index].name, institutions[index].id);
    }
}
