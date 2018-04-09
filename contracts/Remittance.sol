pragma solidity ^0.4.6;

contract Remittance {
    address owner;
    uint public ownerBalance;
    uint deadlineLimit = 10;
    uint serviceFee = 7255 wei;
    bool isActive;

    struct remittanceStruct {
        address remitter;
        uint deadline;
        uint amount;
    }

    mapping (bytes32 => remittanceStruct) remittanceRecords;

    event RemittanceCreated(bytes32 hashValue, address remitter, uint deadline, uint amount);
    event ServiceFeeCharged(uint amount);
    event RemittanceClaimed(bytes32 hashValue, address recipient, uint amount);
    event RemittanceRefunded(bytes32 hashValue, address remitter, uint amount);
    event ServiceFeeReceived(uint amount);
    event ContractActiveStatusChanged(bool status);

    function Remittance() public {
        owner = msg.sender;
        isActive = true;
    }

    modifier isActiveContract() {
        require(isActive);

        _;
    }

    function CheckRemittance(bytes32 hashValue) public view isActiveContract returns (address,uint,uint) {
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        return (remittanceRecord.remitter, remittanceRecord.deadline, remittanceRecord.amount);
    }

    function CreateRemittance(bytes32 hashValue, uint deadline) public payable isActiveContract returns (bool) {
        require(msg.value > serviceFee);
        require(deadline < deadlineLimit);
        require(deadline > 0);
        
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        require(remittanceRecord.deadline == 0);

        remittanceRecord.remitter = msg.sender;
        remittanceRecord.deadline = block.number + deadline;
        remittanceRecord.amount += msg.value - serviceFee;

        remittanceRecords[hashValue] = remittanceRecord;
        RemittanceCreated(hashValue,remittanceRecord.remitter,remittanceRecord.deadline,remittanceRecord.amount);
        ownerBalance += serviceFee;
        ServiceFeeCharged(serviceFee);

        return (true);
    }

    function ClaimRemittanceFunds(string passCode) public isActiveContract returns (bool) {
        bytes32 _hashKey = keccak256(passCode,msg.sender);

        remittanceStruct memory remittanceRecord = remittanceRecords[_hashKey];
        require(remittanceRecord.amount > 0);
        require(block.number <= remittanceRecord.deadline);

        remittanceRecords[_hashKey].amount = 0;

        msg.sender.transfer(remittanceRecord.amount);
        RemittanceClaimed(_hashKey,msg.sender,remittanceRecord.amount);

        return (true);
    }

    function ReclaimFunds(bytes32 hashValue) public isActiveContract returns (bool) {
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        require(remittanceRecord.remitter == msg.sender);
        require(remittanceRecord.amount > 0);
        require(block.number > remittanceRecord.deadline);

        remittanceRecords[hashValue].amount = 0;

        msg.sender.transfer(remittanceRecord.amount);
        RemittanceRefunded(hashValue,msg.sender,remittanceRecord.amount);

        return (true);
    }

    function ClaimFees() public isActiveContract returns (bool) {
        require(owner==msg.sender);
        require(ownerBalance > 0);

        uint _feeToSend = ownerBalance;
        ownerBalance = 0;

        msg.sender.transfer(_feeToSend);
        ServiceFeeReceived(_feeToSend);

        return (true);
    }

    function toggleActiveContract(bool _isActive) public returns (bool) {
        require(owner==msg.sender);

        isActive = _isActive;
        ContractActiveStatusChanged(_isActive);

        return (true);
    }    
}