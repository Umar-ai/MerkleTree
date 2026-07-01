// SPDX-License-Identifier:MIT
pragma solidity ^0.8.34;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirDrop {
    using SafeERC20 for IERC20;
    //It means that we can call functions defined in SafeERC20 for the variable of type IERC20;
    /////////////////////////////
    ///         Errors       ///
    ///////////////////////////
    error MerkleAirDrop__leafNodeVerificationFailed();
    error MerkleAirDrop__userAlreadyClaimedToken();

    /////////////////////////////
    ///         Events       ///
    ///////////////////////////
    event Claim(address indexed account, uint256 indexed amount);

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airDropToken;
    mapping(address => bool) userWhoClaimedTokens;

    constructor(bytes32 _merkleRoot, IERC20 _airDropToken) {
        i_merkleRoot = _merkleRoot;
        i_airDropToken = _airDropToken;
    }

    function claim(address _account, uint256 _amount, bytes32[] calldata _merkleProof) public {
        if (userWhoClaimedTokens[_account]) {
            revert MerkleAirDrop__userAlreadyClaimedToken();
        }
        bytes32 leaf = keccak256(bytes.concat((keccak256(abi.encode(_account, _amount)))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirDrop__leafNodeVerificationFailed();
        }
        userWhoClaimedTokens[_account] = true;
        emit Claim(_account, _amount);
        i_airDropToken.safeTransfer(_account, _amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return i_airDropToken;
    }
}
