// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Attacker {
    receive() external payable {
        require(false, "");
    }
}

contract AttackerTest is Test {
    DeployFundMe deployer;
    FundMe fundMe;
    HelperConfig helperConfig;
    Attacker attacker;

    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.01 ether;

    function setUp() public {
        attacker = new Attacker();
        helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        vm.startPrank(address(attacker));
        fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopPrank();
        vm.deal(USER, STARTING_BALANCE);
    }

    function test_WithdrawFailsForSomeReason() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert(FundMe.FundMe__TransferFailed.selector);
        vm.prank(address(attacker));
        fundMe.withdraw();
    }
}

contract FundMeTest is Test {
    using PriceConverter for AggregatorV3Interface;
    using PriceConverter for uint256;

    DeployFundMe deployer;
    FundMe fundMe;
    HelperConfig helperConfig;

    AggregatorV3Interface s_priceFeed;

    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.01 ether;

    function setUp() public {
        deployer = new DeployFundMe();
        (fundMe, helperConfig) = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
        address feedAddress = helperConfig.activeNetworkConfig();
        s_priceFeed = AggregatorV3Interface(feedAddress);
    }

    function test_PriceFeedVersionIsAccurate() public view {
        uint256 expectedVersion = 4;
        uint256 actualVersion = s_priceFeed.version();
        assert(expectedVersion == actualVersion);
    }

    function test_WithDecimals() public view {
        uint256 number = 5;
        uint256 expectedNumberWithDecimals = number * 10 ** 8;
        uint256 actualNumberWithDecimals = number.withDecimals(s_priceFeed);
        assert(expectedNumberWithDecimals == actualNumberWithDecimals);
    }

    function test_Price() public view {
        uint256 priceOfEthUsd = s_priceFeed.getPrice();
        console.log("Price of Eth In USD: ", priceOfEthUsd);
        assert(priceOfEthUsd > 0);
    }

    function test_ConversionRate() public view {
        uint256 ethAmount = 0.1 ether;
        uint256 convertedEthToUsd = ethAmount.getConversionRate(s_priceFeed);
        console.log(ethAmount, "eth in USD: ", convertedEthToUsd);
        assert(convertedEthToUsd > 0);
    }

    function test_PriceFeedDecimalsIsAccurate() public view {
        uint256 expectedVersion = 8;
        uint256 actualVersion = s_priceFeed.decimals();
        assert(expectedVersion == actualVersion);
    }

    function test_FundFailsWithoutEnoughEth() public {
        vm.expectRevert(FundMe.FundMe__NotEnoughETHSent.selector);
        vm.prank(USER);
        fundMe.fund();
    }

    function test_FundUpdatesDataStructure() public {
        address expectedFunder = USER;
        uint256 expectedFund = SEND_VALUE;

        vm.prank(expectedFunder);
        fundMe.fund{value: expectedFund}();

        address actualFunder = fundMe.getFunder(0);
        uint256 actualFund = fundMe.getFund(expectedFunder);

        assert(expectedFunder == actualFunder);
        assert(expectedFund == actualFund);
    }

    function test_WithdrawFailsWithoutOwner() public {
        vm.expectRevert(FundMe.FundMe__NotOwner.selector);
        vm.prank(USER);
        fundMe.withdraw();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function test_WithdrawResetDataStructureWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        // Assert
        assert(
            endingOwnerBalance == startingOwnerBalance + startingFundMeBalance
        );
        assert(endingFundMeBalance == 0);
        assert(fundMe.getFundersLength() == 0);
        assert(fundMe.getFund(USER) == 0);
    }

    function test_WithdrawResetDataStructureWithMultipleFunders()
        public
        funded
    {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 2;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        // Assert
        assert(
            endingOwnerBalance == startingOwnerBalance + startingFundMeBalance
        );
        assert(endingFundMeBalance == 0);
        assert(fundMe.getFundersLength() == 0);
        assert(fundMe.getFund(USER) == 0);
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            assert(fundMe.getFund(address(i)) == 0);
        }
    }
}
