pragma solidity ^0.4.6;

contract MyContract {

    address public owner;
    uint    public deadline;
    uint    public goal;
    uint    public fundsRaised;
    bool    public isOpen;
    bool    public refundsSent;

    struct FunderStruct {
        address funder;
        uint amount;
    }

    FunderStruct[] public funderStructs;

    event LogContribution(address sender, uint amount);
    event LogRefundSent(address funder, uint amount);
    event LogWithdrawal(address beneficiary, uint amount);

    function MyContract(uint duration, uint _goal) {
        owner = msg.sender;
        deadline = block.number + duration;
        goal = _goal;
        isOpen = true;
    }

    function doSomething() pure returns (bool) {
        return true;
    } 

    function doSomethingElse() pure returns (uint) {
        return 5;
    }

    function isSuccess()
        public
        constant
        returns (bool isIndeed)
        {
            return(fundsRaised >= goal);
        }

    function hasFailed() 
        public
        constant
        returns (bool hasIndeed)
        {
            return (fundsRaised < goal && block.number > deadline);
        }

    function contribute()
        public
        payable
        returns(bool success)
        {
            if (msg.value==0)throw;
            if(isSuccess()) throw;
            if(hasFailed()) throw;

            fundsRaised += msg.value;
            FunderStruct memory newFunder;
            newFunder.funder = msg.sender;
            newFunder.amount = msg.value;
            funderStructs.push(newFunder);
            LogContribution(msg.sender,msg.value);
            return true;
        }

    function withdrawFunds()
        public
        returns (bool success)
        {
            if(msg.sender != owner) throw;
            if (!isSuccess()) throw;
            uint amount = this.balance;
            if (!owner.send(amount)) throw;
            LogWithdrawal(owner, this.balance);
            return true;
        }

        function nameOfIt() returns (bool) {
            return (true);
        }

    function sendRefunds()
        public 
        returns (bool success)
        {
            if (msg.sender != owner) throw;
            if (refundsSent) throw;
            if (!hasFailed()) throw;

            uint funderCount = funderStructs.length;
            for (uint i=0;i<funderCount;i++) {
                funderStructs[i].funder.send(funderStructs[i].amount);
                LogRefundSent(funderStructs[i].funder, funderStructs[i].amount);
            }
            refundsSent = true;
            return true;
        }

}