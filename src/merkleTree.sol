// SPDX-License-Identifier:MIT
pragma solidity ^0.8.34;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirDrop is EIP712 {
    using SafeERC20 for IERC20;
    //It means that we can call functions defined in SafeERC20 for the variable of type IERC20;

    /////////////////////////////
    ///         Errors       ///
    ///////////////////////////
    error MerkleAirDrop__leafNodeVerificationFailed();
    error MerkleAirDrop__userAlreadyClaimedToken();
    error MerkleAirDrop__InvalidSignature();

    /////////////////////////////
    ///         Events       ///
    ///////////////////////////
    event Claim(address indexed account, uint256 indexed amount);

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airDropToken;
    mapping(address => bool) userWhoClaimedTokens;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirDropClaim {
        address account;
        uint256 amount;
    }

    constructor(bytes32 _merkleRoot, IERC20 _airDropToken) EIP712("MerkleAirDrop", "1") {
        i_merkleRoot = _merkleRoot;
        i_airDropToken = _airDropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata _merkleProof, uint8 v, bytes32 r, bytes32 s)
        public
    {
        if (userWhoClaimedTokens[account]) {
            revert MerkleAirDrop__userAlreadyClaimedToken();
        }
        if (!_checkIfSignatureIsValid(account, getMessage(account, amount), v, r, s)) {
            revert MerkleAirDrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat((keccak256(abi.encode(account, amount)))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirDrop__leafNodeVerificationFailed();
        }
        userWhoClaimedTokens[account] = true;
        emit Claim(account, amount);
        i_airDropToken.safeTransfer(account, amount);
    }

    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirDropClaim({account: account, amount: amount})))
        );
    }

    function _checkIfSignatureIsValid(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return i_airDropToken;
    }
}
