// SPDX-License-Identifier:MIT
pragma solidity ^0.8.34;
import {FastToken} from "../../src/fastToken.sol";
import {MerkleAirDrop} from "../../src/merkleTree.sol";
import {DeployMerkleAirDrop} from "../../script/deployMerkleAirDrop.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract testMerkleTree is Test, ZkSyncChainChecker {
    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant AMOUNT = 25 * 1e18;
    uint256 private constant INITIAL_BALANCE = AMOUNT * 4;
    bytes32 public proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 public proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proofs = [proofOne, proofTwo];
    address user;
    uint256 userPrivKey;
    FastToken fastToken;
    MerkleAirDrop merkleAirDrop;
    address anotherUser;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirDrop deployMerkleAirDrop = new DeployMerkleAirDrop();
            (merkleAirDrop, fastToken) = deployMerkleAirDrop.run();
        } else {
            fastToken = new FastToken();
            merkleAirDrop = new MerkleAirDrop(ROOT, fastToken);
            fastToken.mint(fastToken.owner(), INITIAL_BALANCE);
            fastToken.transfer(address(merkleAirDrop), INITIAL_BALANCE);
        }
        (user, userPrivKey) = makeAddrAndKey("user");
        anotherUser = makeAddr("users");
    }

    function testUserCanClaim() public {
        uint256 starting_balance = fastToken.balanceOf(user);
        vm.prank(user);
        merkleAirDrop.claim(user, AMOUNT, proofs);
        uint256 ending_balance = fastToken.balanceOf(user);
        assertEq(ending_balance - starting_balance, AMOUNT);
    }

    function testUserCannotClaimTwice() public {
        vm.prank(user);
        merkleAirDrop.claim(user, AMOUNT, proofs);
        vm.prank(user);
        vm.expectRevert(MerkleAirDrop.MerkleAirDrop__userAlreadyClaimedToken.selector);
        merkleAirDrop.claim(user, AMOUNT, proofs);
    }

    function testUserWhoIsNotOnTheListCannotClaim() public {
        vm.prank(anotherUser);
        vm.expectRevert(MerkleAirDrop.MerkleAirDrop__leafNodeVerificationFailed.selector);
        merkleAirDrop.claim(anotherUser, AMOUNT, proofs);
    }

    function testPerformClaimAndCheckEmittedAddressAndAmount() public {
        vm.recordLogs();
        merkleAirDrop.claim(user, AMOUNT, proofs);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 account = entries[0].topics[1];
        bytes32 amount = entries[0].topics[2];
        address accountAddress = address(uint160(uint256(account)));
        assertEq(accountAddress, user);
        assertEq(uint256(amount), AMOUNT);
    }
}
