// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(0));
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                if (msg.value > amount) {
                    // Return remainder if exist
                    msg.sender.transfer(msg.value.sub(amount));
                }
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
        }
    }

    function uniSymbol(IERC20 token) internal view returns(string memory) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSignature("symbol()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSignature("SYMBOL()")
            );
        }

        if (!success) {
            return _toHex(address(token));
        }

        if (data.length >= 64) {
            // Support symbols with upto 256 length
            if (data[33] == 0) {
                data = abi.decode(data, (bytes));
            } else {
                return _toHex(address(token));
            }
        }

        uint len = 0;
        while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
            len++;
        }

        if (len == 0) {
            return _toHex(address(token));
        }

        bytes memory result = new bytes(len);
        for (uint i = 0; i < len; i++) {
            result[i] = data[i];
        }

        return string(result);
    }

    function _toHex(address account) private pure returns(string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint j = 2;
        for (uint i = 0; i < data.length; i++) {
            uint a = uint8(data[i]) >> 4;
            uint b = uint8(data[i]) & 0x0f;
            str[j++] = byte(uint8(a + 48 + (a/10)*39));
            str[j++] = byte(uint8(b + 48 + (b/10)*39));
        }

        return string(str);
    }
}
