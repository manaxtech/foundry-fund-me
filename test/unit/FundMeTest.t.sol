// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {PriceConverter} from "src/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMeTest is Test, CodeConstants {
    FundMe fundMe;
    DeployFundMe deployer;
    HelperConfig helperConfig;

    address FUNDER = makeAddr("funder");
    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    function setUp() public {
        deployer = new DeployFundMe();
        (fundMe, helperConfig) = deployer.deployFundMe();

        vm.deal(FUNDER, INITIAL_BALANCE);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Variables and constants
    ////////////////////////////////////////////////////////////////////////////////////

    function test_PriceFeedVersionIsAccurate() public {
        address expectedPriceFeedAddress = helperConfig.getConfig().priceFeed;
        address recordedPriceFeedAddress = address(fundMe.getPriceFeed());
        assert(recordedPriceFeedAddress == expectedPriceFeedAddress);
    }

    function test_MinimumUsdIsAccurate() public view {
        uint256 expectedMinimumUsd = 5;
        uint256 recordedMinimumUsd = fundMe.getMinimumUsd();
        assert(recordedMinimumUsd == expectedMinimumUsd);
    }

    function test_OwnerIsMsgSender() public view {
        address recordedOwner = fundMe.getOwner();
        assert(recordedOwner == msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Fund
    ////////////////////////////////////////////////////////////////////////////////////

    function test_FundFailsWithoutEnoughETH() public {
        vm.expectRevert(
            abi.encodeWithSelector(FundMe.FundMe__SendEnoughEth.selector, 0)
        );
        vm.prank(FUNDER);
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(FUNDER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function test_FundUpdatesDataStructureWithSingleFunder() public funded {
        address recordedFunder = fundMe.getFunder(0);
        uint256 recordedFunderFundedAmount = fundMe.getAmountFunded(
            recordedFunder
        );

        assert(recordedFunder == FUNDER);
        assert(recordedFunderFundedAmount == SEND_VALUE);
    }

    function test_FundUpdatesDataStructureWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        address recordedFunder = fundMe.getFunder(0);
        uint256 recordedFunderFundedAmount = fundMe.getAmountFunded(
            recordedFunder
        );

        assert(recordedFunder == FUNDER);
        assert(recordedFunderFundedAmount == SEND_VALUE);

        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            recordedFunder = fundMe.getFunder(uint256(i));
            recordedFunderFundedAmount = fundMe.getAmountFunded(recordedFunder);

            assert(recordedFunder == address(i));
            assert(recordedFunderFundedAmount == SEND_VALUE);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Withdraw
    ////////////////////////////////////////////////////////////////////////////////////

    function test_WithdrawFailsIfNotOwner() public funded {
        vm.expectRevert(FundMe.FundMe__NotOwner.selector);
        vm.prank(FUNDER);
        fundMe.withdraw();
    }

    function test_WithdrawResetsDataStructureWithSingleFunder() public funded {
        // Arrange / Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        assert(fundMe.getFundersLength() == 0);
        assert(fundMe.getAmountFunded(FUNDER) == 0);
    }

    function test_WithdrawResetsDataStructureWithMultipleFunders()
        public
        funded
    {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        assert(fundMe.getAmountFunded(FUNDER) == 0);
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            assert(fundMe.getAmountFunded(address(i)) == 0);
        }
        assert(fundMe.getFundersLength() == 0);
    }

    // with multiple funders
}

contract ReverterOwner {
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}

contract ExtensiveTest is Test {
    address reverterOwner = address(new ReverterOwner());
    FundMe fundMe;
    HelperConfig helperConfig = new HelperConfig();

    address FUNDER = makeAddr("funder");
    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    function setUp() public {
        address priceFeed = helperConfig.getConfig().priceFeed;
        vm.startPrank(reverterOwner);
        fundMe = new FundMe(priceFeed);
        vm.stopPrank();

        vm.deal(FUNDER, INITIAL_BALANCE);
    }

    function test_WithdrawFailIfMoneyTransferFails() public {
        vm.prank(FUNDER);
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert(FundMe.FundMe__TransferFailed.selector);
        vm.prank(reverterOwner);
        fundMe.withdraw();
    }
}

contract PriceConverterTest is Test {
    using PriceConverter for AggregatorV3Interface;
    using PriceConverter for uint256;

    FundMe fundMe;
    DeployFundMe deployer;
    HelperConfig helperConfig;

    address FUNDER = makeAddr("funder");
    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    function setUp() public {
        deployer = new DeployFundMe();
        (fundMe, helperConfig) = deployer.run();

        vm.deal(FUNDER, INITIAL_BALANCE);
    }

    function test_PriceFeedVersionAccurate() public view {
        uint256 expectedPriceFeedVersion = 4;
        uint256 actualPriceFeedVersion = fundMe.getPriceFeed().getVersion();
        assert(actualPriceFeedVersion == expectedPriceFeedVersion);
    }

    function test_PriceFeedDecimalsAccurate() public view {
        uint256 expectedPriceFeedDecimals = 8;
        uint256 actualPriceFeedDecimals = fundMe.getPriceFeed().getDecimals();
        assert(actualPriceFeedDecimals == expectedPriceFeedDecimals);
    }

    function test_WithDecimalsMakeCorrectCalculation() public view {
        uint256 multiplicand = 5;
        uint256 expectedMultiplicandWithDecimals = multiplicand *
            (10 ** fundMe.getPriceFeed().getDecimals());
        uint256 actualMultiplicandWithDecimals = multiplicand.withDecimals(
            fundMe.getPriceFeed()
        );
        assert(
            actualMultiplicandWithDecimals == expectedMultiplicandWithDecimals
        );
    }

    function test_PriceFeedPriceAndConversionRate() public view {
        uint256 minimumEthPriceInUSD = 0;
        uint256 actualEthPriceInUSD = fundMe.getPriceFeed().getPrice();

        uint256 twoEthPriceInUsd = uint256(2 ether).getConversionRate(
            fundMe.getPriceFeed()
        );

        console.log("Recorded Eth Price: ", actualEthPriceInUSD);
        console.log("Two Eth in usd", twoEthPriceInUsd);

        assert(actualEthPriceInUSD > minimumEthPriceInUSD);
        assert(twoEthPriceInUsd > minimumEthPriceInUSD);
    }
}
