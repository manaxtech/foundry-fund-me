// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    /************************ Errors ************************/
    error FundMe__SendEnoughEth(uint256 sendedAmount);
    error FundMe__NotOwner();
    error FundMe__TransferFailed();

    // Chainlink PriceFeed variables
    AggregatorV3Interface private immutable i_priceFeed;

    // FundMe contract variables
    uint256 private constant MINIMUM_USD = 5;
    address private immutable i_owner;
    address[] private s_funders; // remember to test later
    mapping(address => uint256) private s_amountFunded; // remeber to test later

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "NotOwner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeed) {
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(priceFeed);
    }

    receive() external payable {
        // remeber to test later
        fund();
    }

    fallback() external payable {
        // remeber to test later
        fund();
    }

    function fund() public payable {
        // require(
        //     msg.value.getConversionRate(i_priceFeed) >=
        //         MINIMUM_USD.withDecimals(i_priceFeed),
        //     "Send more eth"
        // );
        if (
            msg.value.getConversionRate(i_priceFeed) <
            MINIMUM_USD.withDecimals(i_priceFeed)
        ) {
            revert FundMe__SendEnoughEth(msg.value);
        }
        s_funders.push(msg.sender);
        s_amountFunded[msg.sender] += msg.value;
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_amountFunded[s_funders[i]] = 0;
        }

        s_funders = new address[](0);
        (bool success /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        // require(success, "TransferFailed");
        if (!success) {
            revert FundMe__TransferFailed();
        }
    }

    /***************************** Getter Function *****************************/

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getAmountFunded(address funder) external view returns (uint256) {
        return s_amountFunded[funder];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    /////////////

    function getPriceFeed() external view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getMinimumUsd() external pure returns (uint256) {
        return MINIMUM_USD;
    }

    function getFundersLength() external view returns (uint256) {
        return s_funders.length;
    }
}
