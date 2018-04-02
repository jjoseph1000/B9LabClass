var Mod4PopQuiz2 = artifacts.require("./Mod4PopQuiz2.sol");
var MyContract = artifacts.require("./MyContract.sol");

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


  contract('MyContract', function(accounts) {
    var instance;

    beforeEach(function() {
       return MyContract.deployed()
       .then(function(_instance){
        instance = _instance;
       }); 
    });

    it("should run", function () {
        return instance.doSomething()
        .then(function(success) {
        assert.isTrue(success, "failed to do something");
        return instance.doSomethingElse.call();
      })
      .then(function (resultValue) {
        assert.equal(resultValue.toString(10), "3", "there should be exactly 3 things at this stage");
      });
    });
  });