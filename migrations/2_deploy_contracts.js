var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var Campaign = artifacts.require("./Campaign.sol");
var Mod4PopQuiz2 = artifacts.require("./Mod4PopQuiz2.sol");
var MyContract = artifacts.require("./MyContract.sol");
var Splitter = artifacts.require("./Splitter.sol");
var Remittance = artifacts.require("./Remittance.sol");
var ControlledAccessDonation = artifacts.require("./ControlledAccessDonation.sol");
var RemittanceTest = artifacts.require("./RemittanceTest.sol");
var RockPaperScissors = artifacts.require("./RockPaperScissors.sol");
var PredictFutureHash = artifacts.require("./PredictFutureHash.sol");

module.exports = function(deployer) {
  // deployer.deploy(ConvertLib);
  // deployer.link(ConvertLib, MetaCoin);
  // deployer.deploy(MetaCoin);
  //deployer.deploy(Campaign,50,100);
  // deployer.deploy(Mod4PopQuiz2,50,100);
  deployer.deploy(MyContract,50,100);
  //deployer.deploy(Splitter);
  deployer.deploy(Remittance,true);
  deployer.deploy(RemittanceTest);
  deployer.deploy(ControlledAccessDonation);
  deployer.deploy(RockPaperScissors,true);
  deployer.deploy(PredictFutureHash);
};
