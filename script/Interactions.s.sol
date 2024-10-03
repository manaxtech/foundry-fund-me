// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentDeployment);
    }

    function fundFundMe(address contractAddress) public {
        vm.startBroadcast();
        FundMe(payable(contractAddress)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded with amount: ", SEND_VALUE);
    }
}

contract WithdrawFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentDeployment);
    }

    function withdrawFundMe(address contractAddress) public {
        uint256 withdrawAmount = contractAddress.balance;
        vm.startBroadcast();
        FundMe(payable(contractAddress)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw amount: ", withdrawAmount);
    }
}

contract BalanceFundMe is Script {
    function run() external view returns (uint256) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return balanceFundMe(mostRecentDeployment);
    }

    function balanceFundMe(
        address contractAddress
    ) public view returns (uint256) {
        console.log("Balance of Contract is: ", contractAddress.balance);
        return contractAddress.balance;
    }
}

contract GetFunderFundMe is Script {
    uint256 constant INDEX = 0;

    function run() external returns (address) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return getFunderFundMe(mostRecentDeployment);
    }

    function getFunderFundMe(address contractAddress) public returns (address) {
        address funder;
        vm.startBroadcast();
        funder = FundMe(payable(contractAddress)).getFunder(INDEX);
        vm.stopBroadcast();
        console.log("Funder at index ", INDEX, "is:", funder);

        return funder;
    }
}

contract GetFundersLengthFundMe is Script {
    function run() external returns (uint256) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return getFundersLengthFundMe(mostRecentDeployment);
    }

    function getFundersLengthFundMe(
        address contractAddress
    ) public returns (uint256) {
        uint256 numFunders;
        vm.startBroadcast();
        numFunders = FundMe(payable(contractAddress)).getFundersLength();
        vm.stopBroadcast();
        console.log("Number of funders is ", numFunders);

        return numFunders;
    }
}

contract GetFundFundMe is Script {
    address constant FUNDER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function run() external returns (uint256) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return getFundFundMe(mostRecentDeployment);
    }

    function getFundFundMe(address contractAddress) public returns (uint256) {
        uint256 fund;
        vm.startBroadcast();
        fund = FundMe(payable(contractAddress)).getFund(FUNDER);
        vm.stopBroadcast();
        console.log("Funder ", FUNDER, "funded this amount:", fund);

        return fund;
    }
}

contract GetOwnerFundMe is Script {
    function run() external returns (address) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return getOwnerFundMe(mostRecentDeployment);
    }

    function getOwnerFundMe(address contractAddress) public returns (address) {
        address owner;
        vm.startBroadcast();
        owner = FundMe(payable(contractAddress)).getOwner();
        vm.stopBroadcast();
        console.log("Owner of the contract ", contractAddress, "is:", owner);

        return owner;
    }
}
