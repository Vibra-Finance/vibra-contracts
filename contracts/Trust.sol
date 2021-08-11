// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vibra.sol";

contract Trust {
    Vibra private vibra;
    address public admin;

    constructor(address _vibra) {
        vibra = Vibra(_vibra);
        admin = msg.sender;
    } 
}