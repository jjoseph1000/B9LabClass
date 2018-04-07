pragma solidity ^0.4.6;

contract RemittanceTest {
    function GetHash(string input, address validAccount) public pure returns (bytes32) {
        return (keccak256(input,validAccount));
    }
}