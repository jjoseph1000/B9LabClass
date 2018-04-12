pragma solidity ^0.4.6;

contract Remittance {
    address public owner;
    uint deadlineLimit = 40320;
    uint serviceFee = 7255 wei;
    bool isActive;
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
    event LogContractActiveStatusChanged(bool status);
    event LogOwnershipTransferred(address owner, address newOwner);

    function Remittance(bool _isActive) public {
        owner = msg.sender;
        isActive = _isActive;
    }

    modifier isActiveContract() {
        require(isActive);

        _;
    }

    function checkRemittance(bytes32 hashValue) public view isActiveContract returns (address remitter,uint deadline,uint amount) {
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
        LogRemittanceCreated(hashValue,remittanceRecord.remitter,remittanceRecord.deadline,remittanceRecord.amount,owner,serviceFee);
        unclaimedFeePayment[owner] += serviceFee;

        return (true);
    }

    function claimRemittanceFunds(string passCode) public isActiveContract returns (bool success) {
        bytes32 _hashKey = keccak256(passCode,msg.sender);

        require(remittanceRecords[_hashKey].amount > 0);
        require(block.number <= remittanceRecords[_hashKey].deadline);

        uint remittanceAmount = remittanceRecords[_hashKey].amount;
        remittanceRecords[_hashKey].amount = 0;

        msg.sender.transfer(remittanceAmount);
        LogRemittanceClaimed(_hashKey,msg.sender,remittanceRecords[_hashKey].amount);

        return (true);
    }

    function reclaimFunds(bytes32 hashValue) public isActiveContract returns (bool success) {
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        require(remittanceRecord.remitter == msg.sender);
        require(remittanceRecord.amount > 0);
        require(block.number > remittanceRecord.deadline);

        remittanceRecords[hashValue].amount = 0;

        msg.sender.transfer(remittanceRecord.amount);
        LogRemittanceRefunded(hashValue,msg.sender,remittanceRecord.amount);

        return (true);
    }

    function claimFees() public isActiveContract returns (bool success) {
        require(unclaimedFeePayment[msg.sender] > 0);

        uint _feeToSend = unclaimedFeePayment[msg.sender];
        unclaimedFeePayment[msg.sender] = 0;

        msg.sender.transfer(_feeToSend);
        LogServiceFeeReceived(msg.sender,_feeToSend);

        return (true);
    }

    function getHash(string input, address validAccount) public pure returns (bytes32 hashResult) {
        return (keccak256(input,validAccount));
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        require(newOwner != address(0));
        LogOwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function toggleActiveContract(bool _isActive) public returns (bool success) {
        require(owner==msg.sender);

        isActive = _isActive;
        LogContractActiveStatusChanged(_isActive);

        return (true);
    }    
}