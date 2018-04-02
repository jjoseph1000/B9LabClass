var Splitter = artifacts.require("./Splitter.sol");

 contract('Splitter', function(accounts) {
    var depositer = accounts[0];
    var beneficiary1 = accounts[1]; 
    var beneficiary2 = accounts[2]; 
    var nonBeneficiary = accounts[3];
    var contract;

    beforeEach(function() {
       return Splitter.new({from: depositer})
       .then(function(instance){
           contract = instance;
       }); 
    });

    it("should deposit and split ether", function() {
        var firstAmountBeingDeposited = 17;

        return contract.GetBalanceOf(beneficiary1)
        .then(function(beneficiary1Balance){
            assert.equal(web3.fromWei(beneficiary1Balance.toString(10)),0,"Account owed to beneficiary 1 not correct");
            return contract.GetBalanceOf(beneficiary2);
        })
        .then(function(beneficiary2Balance){
            assert.equal(web3.fromWei(beneficiary2Balance.toString(10)),0,"Account owed to beneficiary 2 not correct");
            return contract.DepositEther(beneficiary1, beneficiary2,{from: depositer, value: web3.toWei(firstAmountBeingDeposited, "ether")})
        })
        .then(function(txn) {
            return web3.eth.getBalance(contract.address);
        })
        .then(function(totalEtherBalance){
            assert.equal(web3.fromWei(totalEtherBalance.toString(10)),firstAmountBeingDeposited,"Total ether in contract is not correct");
            return contract.GetBalanceOf(beneficiary1);
        })
        .then(function(beneficiary1Balance){
            assert.equal(web3.fromWei(beneficiary1Balance.toString(10)),firstAmountBeingDeposited/2,"Account owed to beneficiary 1 not correct");
            return contract.GetBalanceOf(beneficiary2);
        })
        .then(function(beneficiary2Balance){
            assert.equal(web3.fromWei(beneficiary2Balance.toString(10)),firstAmountBeingDeposited/2,"Account owed to beneficiary 2 not correct");
            return contract.GetBalanceOf(nonBeneficiary);
        })
        .then(function(nonBeneficaryBalance){
            assert.equal(web3.fromWei(nonBeneficaryBalance.toString(10)),0,"Non-beneficiary should have no balance");
        })
    });  



 });

