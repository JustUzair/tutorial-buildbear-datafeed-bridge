// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract Bridge {
    using SafeERC20 for IERC20;

    address public admin;
    uint256 public nonce;
    mapping(uint256 => bool) public processedNonces;

    address public wethToken;
    address public usdtToken;
    address public wethUsdFeed;

    event BridgeRequested( // still present, but will be filled by relayer mapping
        address indexed from,
        address indexed to,
        address srcToken,
        address dstToken,
        uint256 srcAmount,
        uint256 dstAmount,
        uint256 nonce,
        uint256 date
    );

    event TransferReleased(address indexed to, address token, uint256 amount, uint256 externalChainNonce, uint256 date);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _weth, address _usdt, address _wethUsdFeed) {
        admin = msg.sender;
        wethToken = _weth;
        usdtToken = _usdt;
        wethUsdFeed = _wethUsdFeed;
    }

    function _getWethPrice() internal view returns (uint256) {
        AggregatorV3Interface feed = AggregatorV3Interface(wethUsdFeed);
        (, int256 answer,,,) = feed.latestRoundData();
        require(answer > 0, "invalid answer");

        uint8 dec = feed.decimals();
        uint256 price = uint256(answer);

        if (dec > 8) price = price / (10 ** (dec - 8));
        else if (dec < 8) price = price * (10 ** (8 - dec));

        return price; // 1e8
    }

    function lockAndQuote(address srcFromToken, address srcToToken, uint256 srcAmount, address to) external {
        IERC20(srcFromToken).safeTransferFrom(msg.sender, address(this), srcAmount);

        uint256 dstAmount;

        uint256 wethPrice = _getWethPrice(); // 1e8

        if (srcFromToken == wethToken && srcToToken == usdtToken) {
            // WETH → USDT
            dstAmount = (srcAmount * wethPrice) / 1e8 / 1e12; // adjust 18→6 decimals
        } else if (srcFromToken == usdtToken && srcToToken == wethToken) {
            // USDT → WETH
            dstAmount = (srcAmount * 1e12 * 1e8) / wethPrice; // adjust 6→18 decimals
        } else {
            revert("unsupported token pair");
        }

        emit BridgeRequested(msg.sender, to, srcFromToken, srcToToken, srcAmount, dstAmount, nonce, block.timestamp);
        nonce++;
    }

    function release(address token, address to, uint256 amount, uint256 externalChainNonce) external onlyAdmin {
        require(!processedNonces[externalChainNonce], "already processed");
        processedNonces[externalChainNonce] = true;

        IERC20(token).safeTransfer(to, amount);

        emit TransferReleased(to, token, amount, externalChainNonce, block.timestamp);
    }
}

interface IERC20Metadata is IERC20 {
    function decimals() external returns (uint8 decimals);
}
