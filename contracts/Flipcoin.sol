pragma solidity 0.5.12;

import "./Ownable.sol";
import "./Destroyable.sol";
//import "https://github.com/provable-things/ethereum-api/provableAPI_0.5.sol";
import "./provableAPI_0.5.sol";

contract FlipCoin is Ownable, Destroyable, usingProvable {

    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
    uint256 public latestNumber;
    uint256 contractBalance;

    event playerStatus(string, bool, uint);
    event LogNewProvableQuery(string description);
    event generatedRandomNumber(address playerAddress, uint256 randomNumber, uint256 coinSide);
    //event proofVerify(string message);
    event debugCallback(address playerAddress, uint256 coinSide, uint betAmt);


    constructor() payable public{
        contractBalance = 0;
    }

    struct Player{
        uint countWin;
        uint countLost;
        uint sumWin;
        bool isActive;
        uint256 coinSide;
        uint betAmount;
    }

    mapping (address => Player) private players;
    mapping (bytes32 => address) private betsQuery;

    address[] private creators;

    modifier costs(uint cost){
        require(msg.value >= cost);
        _;
    }

    function playFlipCoin(uint256 coinSide) public payable costs(.005 ether){
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;

        uint betAmount = msg.value;

        require (contractBalance > 2*msg.value);

        Player memory newPlayer;

        if(!exists(msg.sender)){
            insertPlayer(newPlayer, coinSide, betAmount);
            creators.push(msg.sender);
        }
        else{
            players[msg.sender].coinSide = coinSide;
            players[msg.sender].betAmount = betAmount;
        }

        bytes32 queryId = provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);
        //bytes32 queryId = bytes32(keccak256(abi.encodePacked(msg.sender)));

        betsQuery[queryId] = msg.sender;
        //__callback(queryId, "2", bytes("test"));



        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    }

    function getContractBalance() public view returns (uint){
        return address(this).balance;
    }

    function initalDepositToContract() public payable{
        contractBalance = address(this).balance;
    }

    function withdrawWinAmount(address payable playerAccount) public {
        uint toTransfer;
        address creator = msg.sender;

        toTransfer = players[creator].sumWin;
        resetPlayerStatus();

        playerAccount.transfer(toTransfer);
    }

    function insertPlayer(Player memory newPlayer, uint256 coinSide, uint betAmount) private {
        address creator = msg.sender;

        newPlayer.isActive = true;
        newPlayer.coinSide = coinSide;
        newPlayer.betAmount = betAmount;
        players[creator] = newPlayer;
    }

    function getPlayerStatus() public view returns(uint timesWon, uint timesLost, uint totalWinAmt, bool _active, uint256 coinSide, uint betAmount){
        address creator = msg.sender;
        return (players[creator].countWin, players[creator].countLost, players[creator].sumWin, players[creator].isActive, players[creator].coinSide, players[creator].betAmount);
    }
    function updatePlayerStatus(address playerAddress, bool winResult, uint winAmount) internal {

        if (winResult == true){
            players[playerAddress].countWin++;
            players[playerAddress].sumWin += winAmount;
        }
        else{
            players[playerAddress].countLost++;
        }
    }

    function resetPlayerStatus() internal {
        address creator = msg.sender;

            players[creator].countWin = 0;
            players[creator].sumWin = 0;
            players[creator].countLost = 0;
            players[creator].isActive = false;
            players[creator].coinSide = 0;
            players[creator].betAmount = 0;

    }

    function exists(address playerAddress) public view returns (bool playerExists) {
        uint i;

	    for (i = 0; i < creators.length; i++) {
                if (creators[i] == playerAddress) {
                    return true;
                }
        }
        return false;
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        bool playerWon;
        uint winAmount;


        address playerAddress = betsQuery[_queryId];
        uint userPlayAmount = players[playerAddress].betAmount;

        emit debugCallback(playerAddress, players[playerAddress].coinSide, players[playerAddress].betAmount);


        require(msg.sender == provable_cbAddress());
        //if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
        //     emit proofVerify("Proof verification failed");
        //}
        //else{
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;

            if (players[playerAddress].coinSide == randomNumber){
                playerWon = true;
                winAmount = 2*userPlayAmount;
                contractBalance -= winAmount;
                updatePlayerStatus(playerAddress, playerWon, winAmount);
                emit playerStatus("Player won the bet", playerWon, winAmount);
            }
            else{
                playerWon = false;
                winAmount = 0;
                contractBalance += userPlayAmount;
                updatePlayerStatus(playerAddress, playerWon, winAmount);
                emit playerStatus("Player lost the bet", playerWon, winAmount);
            }

        delete betsQuery[_queryId];
        emit generatedRandomNumber(playerAddress, randomNumber, players[playerAddress].coinSide);
        //}
    }

    function withdrawAll() public onlyOwner returns(uint) {
       uint toTransfer = contractBalance;
       contractBalance = 0;
       msg.sender.transfer(toTransfer);
       return toTransfer;
   }
}
