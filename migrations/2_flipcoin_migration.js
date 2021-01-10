const FlipCoin = artifacts.require("FlipCoin");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(FlipCoin).then(function(instance){
        instance.initalDepositToContract({value: web3.utils.toWei("2.5", "ether"), from: accounts[0]}).then(function(){
            console.log("Success");
          }).catch(function(err){
              console.log("Error: " + err);
          });
      }).catch(function(err){
          console.log("Error: " + err);
      });
}
