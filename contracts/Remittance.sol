pragma solidity ^0.4.6;

contract Remittance {
    address owner;
    uint public ownerBalance;
    uint deadlineLimit = 10;
    uint serviceFee = 7255 wei;

    struct remittanceStruct {
        address remitter;
        uint deadline;
        uint amount;
    }

    mapping (bytes32 => remittanceStruct) remittanceRecords;

    function Remittance() public {
        owner = msg.sender;
    }

    function CreateRemittance(bytes32 hashValue, uint deadline) public payable returns (bool) {
        require(msg.value > serviceFee);
        require(deadline < deadlineLimit);
        
        remittanceStruct memory remittanceRecord;
        remittanceRecord.remitter = msg.sender;
        remittanceRecord.deadline = block.number + deadline;
        remittanceRecord.amount += msg.value - serviceFee;
        ownerBalance += serviceFee;

        remittanceRecords[hashValue] = remittanceRecord;

        return (true);
    }

    function ClaimRemittanceFunds(string passCode) public returns (bool) {
        bytes32 _hashKey = keccak256(passCode,msg.sender);

        remittanceStruct memory remittanceRecord = remittanceRecords[_hashKey];
        require(remittanceRecord.amount > 0);
        require(block.number <= remittanceRecord.deadline);

        remittanceRecords[_hashKey].amount = 0;

        msg.sender.transfer(remittanceRecord.amount);

        return (true);
    }

    function ReclaimFunds(bytes32 hashValue) public returns (bool) {
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        require(remittanceRecord.remitter == msg.sender);
        require(remittanceRecord.amount > 0);
        require(block.number > remittanceRecord.deadline);

        remittanceRecords[hashValue].amount = 0;

        msg.sender.transfer(remittanceRecord.amount);

        return (true);
    }

    function ClaimFees() public returns (bool) {
        require(owner==msg.sender);
        require(ownerBalance > 0);

        uint _feeToSend = ownerBalance;
        ownerBalance = 0;

        msg.sender.transfer(_feeToSend);

        return (true);
    }

    function kill() public {
        require(owner==msg.sender);

        selfdestruct(msg.sender);
    }    
}