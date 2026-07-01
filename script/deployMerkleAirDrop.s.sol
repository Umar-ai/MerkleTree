// SPDX-License-Identifier:MIT
pragma solidity ^0.8.34;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MerkleAirDrop} from "../src/merkleTree.sol";
import {FastToken} from "../src/fastToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployMerkleAirDrop is Script {
    bytes32 private constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant AMOUNT_TO_TRANSFER = 4 * 25 * 1e18;

    function run() external returns (MerkleAirDrop, FastToken) {
        vm.startBroadcast();
        FastToken fastToken = new FastToken();
        MerkleAirDrop merkleAirDrop = new MerkleAirDrop(MERKLE_ROOT, IERC20(fastToken));
        fastToken.mint(fastToken.owner(), AMOUNT_TO_TRANSFER);
        fastToken.transfer(address(merkleAirDrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (merkleAirDrop, fastToken);
    }
}
