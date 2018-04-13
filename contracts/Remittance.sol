pragma solidity ^0.4.6;

import "./ActiveState.sol";

contract Remittance is ActiveState {
    uint deadlineLimit = 40320;
    uint serviceFee = 7255 wei;
    mapping (address => uint) unclaimedFeePayment;

    struct remittanceStruct {
        address remitter;
        uint deadline;
        uint amount;
    }

    mapping (bytes32 => remittanceStruct) remittanceRecords;

    event LogRemittanceCreated(bytes32 hashValue, address remitter, uint deadline, uint amount, address feeRecipient, uint feeAmount);
    event LogRemittanceClaimed(bytes32 hashValue, address recipient, uint amount);
    event LogRemittanceRefunded(bytes32 hashValue, address remitter, uint amount);
    event LogServiceFeeReceived(address feeRecipient, uint amount);

    function Remittance(bool _isActive) ActiveState(_isActive) public {
    }

    function getRemittance(bytes32 hashValue) public view isActiveContract returns (address remitter,uint deadline,uint amount) {
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        return (remittanceRecord.remitter, remittanceRecord.deadline, remittanceRecord.amount);
    }

    function createRemittance(bytes32 hashValue, uint deadline) public payable isActiveContract returns (bool success) {
        require(msg.value > serviceFee);
        require(deadline < deadlineLimit);
        require(deadline > 0);
        
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        require(remittanceRecord.deadline == 0);

        remittanceRecord.remitter = msg.sender;
        remittanceRecord.deadline = block.number + deadline;
        remittanceRecord.amount = msg.value - serviceFee;

        remittanceRecords[hashValue] = remittanceRecord;
        unclaimedFeePayment[owner] += serviceFee;
        LogRemittanceCreated(hashValue,remittanceRecord.remitter,remittanceRecord.deadline,remittanceRecord.amount,owner,serviceFee);

        return (true);
    }

    function claimRemittanceFunds(string passCode) public isActiveContract returns (bool success) {
        bytes32 _hashKey = keccak256(passCode,msg.sender);

        require(remittanceRecords[_hashKey].amount > 0);
        require(block.number <= remittanceRecords[_hashKey].deadline);

        uint remittanceAmount = remittanceRecords[_hashKey].amount;
        remittanceRecords[_hashKey].amount = 0;

        LogRemittanceClaimed(_hashKey,msg.sender,remittanceRecords[_hashKey].amount);
        msg.sender.transfer(remittanceAmount);

        return (true);
    }

    function reclaimFunds(bytes32 hashValue) public isActiveContract returns (bool success) {
        require(remittanceRecords[hashValue].remitter == msg.sender);
        require(remittanceRecords[hashValue].amount > 0);
        require(block.number > remittanceRecords[hashValue].deadline);

        uint fundAmount = remittanceRecords[hashValue].amount;
        remittanceRecords[hashValue].amount = 0;
        LogRemittanceRefunded(hashValue,msg.sender,fundAmount);
        msg.sender.transfer(fundAmount);

        return (true);
    }

    function claimFees() public isActiveContract returns (bool success) {
        require(unclaimedFeePayment[msg.sender] > 0);

        uint _feeToSend = unclaimedFeePayment[msg.sender];
        unclaimedFeePayment[msg.sender] = 0;

        LogServiceFeeReceived(msg.sender,_feeToSend);
        msg.sender.transfer(_feeToSend);

        return (true);
    }

    function getHash(string input, address validAccount) public pure returns (bytes32 hashResult) {
        return (keccak256(input,validAccount));
    }
}