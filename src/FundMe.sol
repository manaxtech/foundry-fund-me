// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    error FundMe__NotOwner();
    error FundMe__NotEnoughETHSent();
    error FundMe__TransferFailed();

    uint256 private constant MINIMUM_USD = 5;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    address[] private s_funders;
    mapping(address => uint256) private s_funds;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        if (
            msg.value.getConversionRate(s_priceFeed) <
            MINIMUM_USD.withDecimals(s_priceFeed)
        ) {
            revert FundMe__NotEnoughETHSent();
        }
        s_funders.push(msg.sender);
        s_funds[msg.sender] += msg.value;
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_funds[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) {
            revert FundMe__TransferFailed();
        }
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /*********************** Getter Functions ***********************/
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getFundersLength() external view returns (uint256) {
        return s_funders.length;
    }

    function getFund(address funder) external view returns (uint256) {
        return s_funds[funder];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
