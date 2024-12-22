// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "src/FundMe.sol";
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
        console.log("Funded Contract ", contractAddress, " with ", SEND_VALUE);
    }
}

contract WithdrawFundMe is Script {
    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentDeployment);
    }

    function withdrawFundMe(address contractAddress) public {
        uint256 withdrawAmount = address(contractAddress).balance;

        vm.startBroadcast();
        FundMe(payable(contractAddress)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw ", withdrawAmount);
    }
}

contract FunderFundMe is Script {
    uint256 constant FUNDER_INDEX = 0;

    function run() external returns (address) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return funderFundMe(mostRecentDeployment);
    }

    function funderFundMe(address contractAddress) public returns (address) {
        vm.startBroadcast();
        address funder = FundMe(payable(contractAddress)).getFunder(
            FUNDER_INDEX
        );
        vm.stopBroadcast();
        return funder;
    }
}

contract AmountFundedFundMe is Script {
    function run() external returns (uint256) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return amountFundedFundMe(mostRecentDeployment);
    }

    function amountFundedFundMe(
        address contractAddress
    ) public returns (uint256) {
        address FUNDER = FundMe(payable(contractAddress)).getFunder(0);
        vm.startBroadcast();
        uint256 amountFunded = FundMe(payable(contractAddress)).getAmountFunded(
            FUNDER
        );
        vm.stopBroadcast();
        return amountFunded;
    }
}

contract OwnerFundMe is Script {
    uint256 constant FUNDER_INDEX = 0;

    function run() external returns (address) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        return ownerFundMe(mostRecentDeployment);
    }

    function ownerFundMe(address contractAddress) public returns (address) {
        vm.startBroadcast();
        address owner = FundMe(payable(contractAddress)).getOwner();
        vm.stopBroadcast();
        return owner;
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
        return contractAddress.balance;
    }
}
