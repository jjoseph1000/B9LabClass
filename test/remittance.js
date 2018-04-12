var Remittance = artifacts.require("./Remittance.sol");
var RemittanceTest = artifacts.require("./RemittanceTest.sol");

 contract('Remittance', function(accounts) {
    var contractCreator = accounts[0];
    var remittance;
    var remittancetest;

    beforeEach(function() {
       return Remittance.new({from:contractCreator})
       .then(function(instance){
            remittance = instance;
            return RemittanceTest.new();
       })
       .then(function(instance){
            remittancetest = instance;
       });
    });

    it("should be able to create a remittance", function() {
        var remitter1 = accounts[1];
        var recipient1 = accounts[2];
        var falseReceiver1 = accounts[3];
        var passCode1 = "hello";
        var fakePasscode1 = "goodbye";

        

        return remittancetest.GetHash(passCode1,recipient1)
        .then(function(_hashString){
            hashString = _hashString;
            var hashByte = new String(hashString);
            return remittance.CreateRemittance(hashByte.valueOf(),8,{from:remitter1,value:web3.toWei(30,"ether")})
            .then(function(success){
                return remittance.ClaimRemittanceFunds(passCode1,{from:recipient1});
            })
            .then(function(success){
                return remittance.ClaimRemittanceFunds(passCode1,{from:recipient1});
            })
            .then(function(success){

            });
        });
    });  
 });

