// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./PiggyBank.sol";

contract PiggyBankFactory {
    address public developer;
    

    struct DeployedPiggyBankInfo {
        address deployer;
        address deployedPiggyBank;
    }

    constructor() {
        developer = msg.sender;
    }

    mapping(address => DeployedPiggyBankInfo[]) allPiggyBanksByAuser; // to track multiple piggy bank contracts that have been deployed by each user address

    DeployedPiggyBankInfo[] allPiggyBanks; // all piggies address

    event PiggyBankCreated(address indexed piggyBankAddress, address indexed piggyBankOwner);

    // function to create a new piggyBank using CREATE 2
    function createPiggyBank(
        string memory _savingPurpose,
        uint256 _duration
    ) external returns (address) {
        if (msg.sender == address(0)) revert Errors.AddressZeroDetected();

        // Generate a random salt using some current block informations and sender address
        bytes32 uniqueSalt = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                blockhash(block.number - 1) // hash of the previous block
            )
        );

        address newPiggyBank = address(new PiggyBank{salt: uniqueSalt}(_savingPurpose, _duration, developer));

        DeployedPiggyBankInfo memory newDeployedPiggyBankInfo;
        newDeployedPiggyBankInfo.deployer = msg.sender;
        newDeployedPiggyBankInfo.deployedPiggyBank = newPiggyBank;

        allPiggyBanksByAuser[msg.sender].push(newDeployedPiggyBankInfo);

        allPiggyBanks.push(newDeployedPiggyBankInfo);

        emit PiggyBankCreated(newPiggyBank, msg.sender);

        return newPiggyBank;
    } 

    // function to get all piggy banks
    function getAllPiggyBans() external view returns (DeployedPiggyBankInfo[] memory) {
        return allPiggyBanks;
    }

    // function to get all piggyBanks by a user
    function getUserPiggyBanks() external view returns (DeployedPiggyBankInfo[] memory) {
        return allPiggyBanksByAuser[msg.sender];
    }

    // function to get one of the piggyBanks of a user using array index
    function getUserPiggyBank(uint256 _index) external view returns (address){
        require(_index < allPiggyBanksByAuser[msg.sender].length, "Index out of range"); // check if index is within array length

        DeployedPiggyBankInfo memory deployedPiggyBankInfo = allPiggyBanksByAuser[msg.sender][_index]; 
        
        return deployedPiggyBankInfo.deployedPiggyBank;
    }
    
}