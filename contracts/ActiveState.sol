pragma solidity ^0.4.6;

import "./Ownable.sol";

contract ActiveState is Ownable {
  bool private isActive;


    event LogContractActiveStatusChanged(address currentOwner,bool status);

    function ActiveState(bool _isActive) public {
      isActive = _isActive;
    }

    modifier isActiveContract() {
        require(isActive);

        _;
    }

    function getIsActive() public view returns (bool _activeValue) {
        return (isActive);
    }

    function toggleActiveContract(bool _isActive) public onlyOwner returns (bool success) {
        isActive = _isActive;
        LogContractActiveStatusChanged(msg.sender,_isActive);

        return (true);
    }    
}
