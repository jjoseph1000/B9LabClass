pragma solidity ^0.4.19;
contract PredictFutureHash {
  function PredictFutureHash() public {   
  }
  
  function getCurrentBlock() public view returns (uint blockNumber) {
      
      return (block.number);
  }
  
  function getBlockHash(uint blockNumber) public view returns (bytes32 blockHash) {
      return (block.blockhash(blockNumber));
  }
  
}