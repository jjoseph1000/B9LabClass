pragma solidity ^0.4.6;

contract Remittance {
    address owner;
    uint public ownerBalance;
    bool transferInProgress;
    uint deadlineLimit = 10;
    uint serviceFee = 0.0007255 ether;

    struct remittanceStruct {
        address remitter;
        uint deadline;
        uint amount;
    }

    mapping (bytes32 => remittanceStruct) remittanceRecords;

    function Remittance() public {
        owner = msg.sender;
        transferInProgress = false;
    }

    modifier preventRecursion() {
        if(transferInProgress == false) {
            transferInProgress = true;

            _;

            transferInProgress = false;
        }
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

    function ClaimRemittanceFunds(string passCode) public preventRecursion returns (bool) {
        bytes32 _hashKey = keccak256(passCode,msg.sender);

        remittanceStruct memory remittanceRecord = remittanceRecords[_hashKey];
        require(remittanceRecord.amount > 0);
        require(block.number <= remittanceRecord.deadline);

        msg.sender.transfer(remittanceRecord.amount);

        remittanceRecords[_hashKey].amount = 0;

        return (true);
    }

    function ReclaimFunds(bytes32 hashValue) public preventRecursion returns (bool) {
        remittanceStruct memory remittanceRecord = remittanceRecords[hashValue];
        require(remittanceRecord.remitter == msg.sender);
        require(remittanceRecord.amount > 0);
        require(block.number > remittanceRecord.deadline);

        msg.sender.transfer(remittanceRecord.amount);

        remittanceRecords[hashValue].amount = 0;

        return (true);
    }

    function ClaimFees() public preventRecursion returns (bool) {
        require(owner==msg.sender);
        require(ownerBalance > 0);

        msg.sender.transfer(ownerBalance);

        ownerBalance = 0;

        return (true);
    }

    function kill() public {
        require(owner==msg.sender);

        selfdestruct(msg.sender);
    }    
}