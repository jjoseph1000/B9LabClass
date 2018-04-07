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
        var remitter = accounts[1];
        var recipient = accounts[2];
        var falseReceiver = accounts[3];
        var passCode = "hello";
        var fakePasscode = "goodbye";
        var byteValue;

        return remittancetest.GetHash(passCode,recipient)
        .then(function(_byteValue){
            byteValue = _byteValue;
            return remittance.CreateRemittance(byteValue,8,{from:remitter,value:web3.toWei(30,"ether")})
            .then(function(success){
                assert.strictEqual(success,true,"Not successful creation of remittance");
            })
        });
    });  
 });

