var ControlledAccessDonation = artifacts.require("./ControlledAccessDonation.sol");

// contract('Mod4PopQuiz2', function(accounts) {
//     var goal =  1000;
//     var duration = 10;
//     var contract;
//     var expectedDeadline;

//     var owner = accounts[0];
//     var funder1 = accounts[1]; var contribution1 = 1;
//     var funder2 = accounts[2]; var contribution2 = 10;

//     beforeEach(function() {
//        return Mod4PopQuiz2.new(duration, goal, {from: owner})
//        .then(function(instance){
//            contract = instance;
//            expectedDeadline = web3.eth.blockNumber + duration;
//        }); 
//     });

//     it("should just say hello", function() {
//         assert.strictEqual(true, true,"Something is wrong.");
//     });

//     it("shold be owned by owner", function() {
//         return contract.owner({from: owner})
//         .then(function(_owner) {
//             assert.strictEqual(_owner,owner,"Contract is not owned by owner");
//         });
//     });

//     it("should have a deadline", function() {
//         return contract.deadline({from:owner})
//         .then(function(_deadline) {
//             assert.equal(_deadline.toString(10), expectedDeadline, "Deadline is incorrect")
//         });
//     });

//     it("should return a txn hash", function(){
//         return contract.contract.nameOfIt()
//         .then(function(_txnHash){
//             assert.equal(_txnHash,"free","Returned " + _txnHash);
//         })
//     })

// });

// contract('MyContract', function(accounts) {
//     var goal =  1000;
//     var duration = 10;
//     var contract;
//     var expectedDeadline;
//     var doSomethingSuccess;

//     var owner = accounts[0];
//     var funder1 = accounts[1]; var contribution1 = 1;
//     var funder2 = accounts[2]; var contribution2 = 10;

//     beforeEach(function() {
//        return MyContract.new(duration, goal, {from: owner})
//        .then(function(instance){
//            contract = instance;
//            expectedDeadline = web3.eth.blockNumber + duration;
//        }); 
//     });

//     it("should run", function () {
//         return contract.doSomething()
//       .then(function(success) {
//         doSomethingSuccess = success;
//         return contract.doSomethingElse();
//       })
//       .then(function (resultValue) {
//         assert.isTrue(doSomethingSuccess, "failed to do something");
//         assert.equal(resultValue.toString(10), "3", "there should be exactly 3 things at this stage");
//       });
//     });

//     it("should run 2", function (done) {
//         var instance;
//         MyContract.deployed()
//         .then(_instance => {
//           instance = _instance;
//           return instance.doSomething();
//         })
//         .then(function (txObject) {
//           assert.isOk(txObject, "failed to do something");
//           return instance.doSomethingElse.call();
//         })
//         .then(function (resultValue) {
//           assert.equal(resultValue.toString(10), "3", "there should be exactly 3 things at this stage");
//           done();
//         })
//         .catch(done);
//       });    
//   });


  contract('ControlledAccessDonation', function(accounts) {
    var instance;
    var address = accounts[0]

    beforeEach(function() {
       return ControlledAccessDonation.deployed()
       .then(function(_instance){
        instance = _instance;
       }); 
    });


    it('ecrecover result matches address', async function() {
      var msg = '0x8CbaC5e4d803bE2A3A5cd3DbE7174504c6DD0c1C'
  
      var h = web3.sha3(msg)
      var sig = web3.eth.sign(address, h).slice(2)
      var r = `0x${sig.slice(0, 64)}`
      var s = `0x${sig.slice(64, 128)}`
      var v = web3.toDecimal(sig.slice(128, 130)) + 27
  
      return instance.testRecovery.call(h, v, r, s)
      .then(function(result){
        assert.equal(result, address)
          
      });    
    });
  });