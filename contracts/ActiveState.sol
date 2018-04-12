pragma solidity ^0.4.6;

import "./Ownable.sol";

contract ActiveState is Ownable {
  bool isActive;


    event LogContractActiveStatusChanged(bool status);

    function ActiveState() public {
    }

    modifier isActiveContract() {
        require(isActive);

        _;
    }

    function toggleActiveContract(bool _isActive) public onlyOwner returns (bool success) {
        isActive = _isActive;
        LogContractActiveStatusChanged(_isActive);

        return (true);
    }    
}
