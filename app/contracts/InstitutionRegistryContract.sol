// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/@openzeppelin/Ownable.sol";

contract InstitutionRegistryContract is Ownable {
    struct Institution {
        bytes32 name;
        uint id;
    }

    mapping(uint => Institution) public institutions;
    mapping(bytes32 => uint) private nameToId;

    function addInstitution(bytes32 name, uint id) public onlyOwner {
        require(
            institutions[id].id == 0,
            "Institution with this ID already exists"
        );
        require(
            nameToId[name] == 0,
            "Institution with this name already exists"
        );

        Institution memory newInstitution = Institution({name: name, id: id});

        institutions[id] = newInstitution;
        nameToId[name] = id;
    }

    function deleteInstitution(bytes32 name) public onlyOwner {
        uint id = nameToId[name];
        require(
            institutions[id].id != 0,
            "No institution with this name exists"
        );

        delete institutions[id];
        delete nameToId[name];
    }
}
