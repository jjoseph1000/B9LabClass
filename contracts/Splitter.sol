pragma solidity ^0.4.6;

contract Splitter {
    mapping (address => uint) balances;
    address owner;
    bool transferInProgress;

    event LogDeposit(address beneficiary, uint amount);
    event LogWithdrawal(address beneficiary, uint amount);

    function Splitter() {
        owner = msg.sender;
        transferInProgress = false;
    }

    function DepositEther(address recipientOne, address recipientTwo) public payable returns (bool) {
        require(msg.value > 0);

        return SplitDeposit(recipientOne,recipientTwo,msg.value);
    }

    function kill() public {
        require(owner==msg.sender);

        selfdestruct(msg.sender);
    }

    function SplitDeposit(address beneficiaryOne, address beneficiaryTwo, uint totalDeposit) internal returns (bool) {
        require(totalDeposit > 0);
        
        uint depositPerAccount = totalDeposit/2;
        uint depositPerAccountRemainder = totalDeposit % 2;
        balances[beneficiaryOne] += depositPerAccount;
        LogDeposit(beneficiaryOne,depositPerAccount);
        balances[beneficiaryTwo] += depositPerAccount;    
        LogDeposit(beneficiaryTwo,depositPerAccount);
        balances[msg.sender] += depositPerAccountRemainder;
        LogDeposit(msg.sender,depositPerAccountRemainder);

        return true;  
    }

    modifier preventRecursion() {
        if(transferInProgress == false) {
            transferInProgress = true;

            _;

            transferInProgress = false;
        }
    }

    function WithdrawBalance() public preventRecursion returns (bool) {
        require(balances[msg.sender] > 0);

        msg.sender.transfer(balances[msg.sender]);
        LogWithdrawal(msg.sender,balances[msg.sender]);
        balances[msg.sender] = 0;

        return true;
    }

    function GetBalanceOf(address beneficiary) public view returns (uint) {
        return (balances[beneficiary]);
    }



}