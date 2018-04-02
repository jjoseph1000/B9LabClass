pragma solidity ^0.4.6;

contract Splitter {
    mapping (address => uint) balances;

    event LogDeposit(address beneficiary, uint amount);
    event LogWithdrawal(address beneficiary, uint amount);

    function Splitter() {
    }

    function DepositEther(address recipientOne, address recipientTwo) public payable returns (bool) {
        require(msg.value > 0);

        return SplitDeposit(recipientOne,recipientTwo,msg.value);
    }

    function SplitDeposit(address beneficiaryOne, address beneficiaryTwo, uint totalDeposit) internal returns (bool) {
        uint depositPerAccount = totalDeposit/2;
        balances[beneficiaryOne] += depositPerAccount;
        LogDeposit(beneficiaryOne,depositPerAccount);
        balances[beneficiaryTwo] += depositPerAccount;    
        LogDeposit(beneficiaryTwo,depositPerAccount);

        return true;  
    }

    function WithdrawBalance() public returns (bool) {
        require(balances[msg.sender] > 0);

        if (msg.sender.send(balances[msg.sender])) {
            uint withdrawalAmount = balances[msg.sender];
            balances[msg.sender] = 0;
            LogWithdrawal(msg.sender,withdrawalAmount);
        }

        return true;
    }

    function GetBalanceOf(address beneficiary) public view returns (uint) {
        return (balances[beneficiary]);
    }



}