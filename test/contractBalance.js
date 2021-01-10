const FlipCoin = artifacts.require("FlipCoin");
const truffleAssert = require("truffle-assertions");

contract("FlipCoin", async function(accounts){

    let instance;
    let contractAddress;
    let initialContractBalance;
    let initialOwnerBalance;

	before(async function(){
		instance = await FlipCoin.deployed();
		contractAddress = FlipCoin.address;
        initialOwnerBalance = await web3.eth.getBalance(accounts[0]);
        console.log("initialOwnerBalance is: " + initialOwnerBalance);
		console.log("Deployed contract's address is: " + contractAddress);
		initialContractBalance = await instance.getContractBalance();
		console.log("Initial Contract balance is: " + initialContractBalance);
	});

    it("Test1: check contract balance matches the blockchain contract balance", async function(){
        await instance.playFlipCoin(1, {value: web3.utils.toWei(".05", "ether"), from: accounts[4]});
        let newBalance = await instance.getContractBalance();
        console.log("Updated Contract balance after flip coin play: " + newBalance.toString());

        let onChainBalance = await web3.eth.getBalance(FlipCoin.address);
        console.log("Onchain contract balance is: " + onChainBalance);
        assert(newBalance.toString() === onChainBalance, "The contract balance do not match");
    });
    it("Test1: check contract balance matches the blockchain contract balance", async function(){
        await instance.playFlipCoin(0, {value: web3.utils.toWei(".05", "ether"), from: accounts[4]});
        let newBalance = await instance.getContractBalance();
        console.log("Updated Contract balance after flip coin play: " + newBalance.toString());

        let onChainBalance = await web3.eth.getBalance(FlipCoin.address);
        console.log("Onchain contract balance is: " + onChainBalance);
        assert(newBalance.toString() === onChainBalance, "The contract balance do not match");
    });

});
