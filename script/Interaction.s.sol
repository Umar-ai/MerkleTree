// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.34;


import {DevOpsTools} from 'foundry-devops/src/DevOpsTools.sol';
import {Script} from 'forge-std/Script.sol';
import {MerkleAirDrop} from '../src/merkleTree.sol';


contract InteractionWithMerkleAirDrop is Script{

    error InteractionWithMerkleAirDrop__InvalidSignatureLength();


    address private constant CLAIMING_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant AMOUNT=25*1e18;
  
    bytes32 proofOne=0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proofTwo=0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[]  proof=[proofOne,proofTwo];
    bytes Signature=hex"aba18789a3d419a29f4e05dbf5659eb02b19d94b48e17c00fe709bc11273f4253f6eba8120c1b1a4b4a9c8fa56218ad80ed42ec6d5e166b09ccd65064e4a306d1c";


    function run() public{
        address mostRecentlyDeployedContract=DevOpsTools.get_most_recent_deployment("MerkleAirDrop",block.chainid);
        claimMerkleAirDrop(mostRecentlyDeployedContract);
    }
    function claimMerkleAirDrop(address merkleAirDropRecentlyDeployedAddress)public{
        vm.startBroadcast();
        (uint8 v,bytes32 r,bytes32 s)=splitSignature(Signature);
        MerkleAirDrop(merkleAirDropRecentlyDeployedAddress).claim(CLAIMING_ADDRESS,AMOUNT,proof,v,r,s);
        vm.stopBroadcast();
    }
    function splitSignature(bytes memory signature)internal pure returns(uint8 v,bytes32 r,bytes32 s){
            if (signature.length != 65) {
            revert InteractionWithMerkleAirDrop__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }


    }


}