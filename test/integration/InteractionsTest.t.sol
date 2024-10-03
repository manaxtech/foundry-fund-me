// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {FundFundMe, WithdrawFundMe, GetFunderFundMe, GetFundFundMe, GetOwnerFundMe, GetFundersLengthFundMe, BalanceFundMe} from "../../script/Interactions.s.sol";

contract FundMeTest is Test {
    DeployFundMe deployer;
    FundMe fundMe;
    HelperConfig helperConfig;

    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.01 ether;

    function setUp() public {
        deployer = new DeployFundMe();
        (fundMe, ) = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function test_UserCanFundAndWithdraw() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        BalanceFundMe balanceFundMe = new BalanceFundMe();
        balanceFundMe.balanceFundMe(address(fundMe));

        GetFunderFundMe getFunderFundMe = new GetFunderFundMe();
        getFunderFundMe.getFunderFundMe(address(fundMe));

        GetFundersLengthFundMe getFundersLengthFundMe = new GetFundersLengthFundMe();
        getFundersLengthFundMe.getFundersLengthFundMe(address(fundMe));

        GetFundFundMe getFundFundMe = new GetFundFundMe();
        getFundFundMe.getFundFundMe(address(fundMe));

        GetOwnerFundMe getOwnerFundMe = new GetOwnerFundMe();
        getOwnerFundMe.getOwnerFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));
    }
}
