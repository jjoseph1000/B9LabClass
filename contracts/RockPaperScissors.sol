pragma solidity ^0.4.6;

import "./ActiveState.sol";

contract RockPaperScissors is ActiveState {
    function RockPaperScissors(bool _isActive) ActiveState(_isActive) public {
    }

    enum ToolChoice {
        rock,
        scissors,
        paper
    }

    enum GameProgression {
        NoToolsSelected,
        OnePlayerPickedHiddenTool,
        BothPlayersPickedHiddenTool,
        OnePlayerRevealedTool
    }

    struct playerStruct {
        bytes32 hiddenToolChoice;
        ToolChoice toolChoice;
        uint amount;
    }

    struct rockPaperScissorsGameStruct {
        mapping (address => playerStruct) playerChoice;
        GameProgression gameProgression;
    }

    mapping (bytes32 => rockPaperScissorsGameStruct) rockPaperScissorsGame;
    mapping (address => uint) winnings;

    function startGame(address opponent) public returns (bool success) {
        require(opponent != address(0));
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        require(rockPaperScissorsGame[hashValue].gameProgression == GameProgression.BothPlayersPickedHiddenTool);
        
        
        return (true);
    }

    function getGameProgression(address opponent) public returns (uint gameProgression) {
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        rockPaperScissorsGameStruct memory gameRecord = rockPaperScissorsGame[hashValue];
        return (uint(gameRecord.gameProgression));
    }

    function pickHiddenTool(address opponent, bytes32 hiddenTool) public payable returns (bool success) {
        require(opponent != address(0));
        require(msg.value > 0);
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        require(rockPaperScissorsGame[hashValue].gameProgression < GameProgression.BothPlayersPickedHiddenTool);
                
        rockPaperScissorsGame[hashValue].playerChoice[msg.sender].hiddenToolChoice = hiddenTool;
        rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount = msg.value;   

        if (rockPaperScissorsGame[hashValue].playerChoice[opponent].hiddenToolChoice == "0x0")
        {
            rockPaperScissorsGame[hashValue].gameProgression = GameProgression.OnePlayerPickedHiddenTool;
        }
        else
        {
            rockPaperScissorsGame[hashValue].gameProgression = GameProgression.BothPlayersPickedHiddenTool;
        }
    }

    function revealHiddenTool(address opponent, string secretCode) public returns (bool success) {
        require(opponent != address(0));
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        require(rockPaperScissorsGame[hashValue].gameProgression == GameProgression.BothPlayersPickedHiddenTool || rockPaperScissorsGame[hashValue].gameProgression == GameProgression.OnePlayerRevealedTool);

        bytes32 hiddenToolChoice = rockPaperScissorsGame[hashValue].playerChoice[msg.sender].hiddenToolChoice;
        if (getHashForSecretlyPickingTool(0,secretCode,msg.sender)==hiddenToolChoice)
        {
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].toolChoice = ToolChoice.rock;
        }
        else if (getHashForSecretlyPickingTool(1,secretCode,msg.sender)==hiddenToolChoice)
        {
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].toolChoice = ToolChoice.scissors;
        }
        else if (getHashForSecretlyPickingTool(2,secretCode,msg.sender)==hiddenToolChoice)
        {
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].toolChoice = ToolChoice.paper;
        }
        else
        {
            throw;
        }

        if (rockPaperScissorsGame[hashValue].gameProgression == GameProgression.BothPlayersPickedHiddenTool)
        {
            rockPaperScissorsGame[hashValue].gameProgression = GameProgression.OnePlayerRevealedTool;
        }
        else
        {

        }

        return (true);
    }

    function getHashForSecretlyPickingTool(uint tool, string secretCode, address validAccount) public view returns (bytes32 hashResult) {
        return (keccak256(tool,secretCode,validAccount));
    }

    function determineToolFromNumber(uint tool) internal view returns (ToolChoice toolChoice) {
        require(tool >= 0 && tool < 3);
        if (uint(ToolChoice.rock)==tool)
        {
            toolChoice = ToolChoice.rock;
        }
        else if (uint(ToolChoice.scissors)==tool)
        {
            toolChoice = ToolChoice.scissors;
        }
        else if (uint(ToolChoice.paper)==tool)
        {
            toolChoice = ToolChoice.paper;
        }        

        return (toolChoice);
    }


    function getHashForUniqueGame(address primary, address secondary) public pure returns (bytes32 hashResult) {
        address firstAddress;
        address secondAddress;

        if (primary < secondary)
        {
            firstAddress = primary;
            secondAddress = secondary;
        }
        else
        {
            firstAddress = secondary;
            secondAddress = primary;
        }


        return (keccak256(firstAddress,secondAddress));
    }

    function GetHash(string input, address validAccount) public pure returns (bytes32) {
        return (keccak256(input,validAccount));
    }
    
}