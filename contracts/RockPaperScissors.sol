pragma solidity ^0.4.6;

import "./ActiveState.sol";

contract RockPaperScissors is ActiveState {
    function RockPaperScissors(bool _isActive) ActiveState(_isActive) public {
    }

    enum ToolChoice {
        notool,
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

    function getGameProgression(address opponent) public isActiveContract returns (uint gameProgression, address, bytes32,  address, bytes32) {
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        rockPaperScissorsGameStruct gameRecord = rockPaperScissorsGame[hashValue];
        return (uint(gameRecord.gameProgression),msg.sender,rockPaperScissorsGame[hashValue].playerChoice[msg.sender].hiddenToolChoice,opponent,rockPaperScissorsGame[hashValue].playerChoice[opponent].hiddenToolChoice);
    }
    /*
        User will pick opponent they want to play against and submit their tool as hidden hash value.
     */

    function pickHiddenTool(address opponent, bytes32 hiddenTool) public isActiveContract payable returns (bool success) {
        require(opponent != address(0));

        //  The total of their previous winnings + ether submitted must be greater than nothing to play.
        uint totalToWager = winnings[msg.sender] + msg.value;
        require(totalToWager > 0);

        // Tool choice will be saved in hash form.
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        require(rockPaperScissorsGame[hashValue].gameProgression < GameProgression.BothPlayersPickedHiddenTool);
                
        rockPaperScissorsGame[hashValue].playerChoice[msg.sender].hiddenToolChoice = hiddenTool;
        rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount = totalToWager;   
        winnings[msg.sender] = 0;

        if (rockPaperScissorsGame[hashValue].playerChoice[opponent].hiddenToolChoice == 0x0)
        {
            rockPaperScissorsGame[hashValue].gameProgression = GameProgression.OnePlayerPickedHiddenTool;
        }
        else
        {
            rockPaperScissorsGame[hashValue].gameProgression = GameProgression.BothPlayersPickedHiddenTool;
        }
    }

    /*
        Using thier secret code, their tool is revealed and saved.   If the player is the second to reveal
        then the determination will be made as to who won and their account will be credited  with all the ether 
        and the unique game will reset.
     */
    function revealHiddenTool(address opponent, string secretCode) public isActiveContract returns (bool success) {
        require(opponent != address(0));
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        require(rockPaperScissorsGame[hashValue].gameProgression == GameProgression.BothPlayersPickedHiddenTool || rockPaperScissorsGame[hashValue].gameProgression == GameProgression.OnePlayerRevealedTool);

        bytes32 hiddenToolChoice = rockPaperScissorsGame[hashValue].playerChoice[msg.sender].hiddenToolChoice;
        if (getHashForSecretlyPickingTool(1,secretCode,msg.sender)==hiddenToolChoice)
        {
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].toolChoice = ToolChoice.rock;
        }
        else if (getHashForSecretlyPickingTool(2,secretCode,msg.sender)==hiddenToolChoice)
        {
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].toolChoice = ToolChoice.scissors;
        }
        else if (getHashForSecretlyPickingTool(3,secretCode,msg.sender)==hiddenToolChoice)
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
            ToolChoice toolChoice = rockPaperScissorsGame[hashValue].playerChoice[msg.sender].toolChoice;
            ToolChoice opponentToolChoice = rockPaperScissorsGame[hashValue].playerChoice[opponent].toolChoice;

            if (toolChoice == ToolChoice.rock)
            {
                if (opponentToolChoice == ToolChoice.rock)
                {
                    winnings[msg.sender] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount;
                    winnings[opponent] += rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.scissors)
                {
                    winnings[msg.sender] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.paper)
                {
                    winnings[opponent] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
            }
            else if (toolChoice == ToolChoice.scissors)
            {
                if (opponentToolChoice == ToolChoice.rock)
                {
                    winnings[opponent] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.scissors)
                {
                    winnings[msg.sender] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount;
                    winnings[opponent] += rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.paper)
                {
                    winnings[msg.sender] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
            }
            else if (toolChoice == ToolChoice.paper)
            {
                if (opponentToolChoice == ToolChoice.rock)
                {
                    winnings[msg.sender] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.scissors)
                {
                    winnings[opponent] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.paper)
                {
                    winnings[msg.sender] += rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount;
                    winnings[opponent] += rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
            }

            rockPaperScissorsGame[hashValue].gameProgression = GameProgression.NoToolsSelected;
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].hiddenToolChoice = 0x0;
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].toolChoice = ToolChoice.notool;
            rockPaperScissorsGame[hashValue].playerChoice[msg.sender].amount = 0;
            rockPaperScissorsGame[hashValue].playerChoice[opponent].hiddenToolChoice = 0x0;
            rockPaperScissorsGame[hashValue].playerChoice[opponent].toolChoice = ToolChoice.notool;
            rockPaperScissorsGame[hashValue].playerChoice[opponent].amount = 0;
            
            
        }

        return (true);
    }

    function balanceOf(address player) public isActiveContract view returns (uint amount) {
        return (winnings[player]);
    }

    function claimWinnings() public isActiveContract returns (bool success) {
        require(winnings[msg.sender] > 0);

        uint winningProceeds = winnings[msg.sender];
        winnings[msg.sender] = 0;
        msg.sender.transfer(winningProceeds);
    }

    /* Used for hashing the tool preference for game  */
    function getHashForSecretlyPickingTool(uint tool, string secretCode, address validAccount) public view isActiveContract returns (bytes32 hashResult) {
        return (keccak256(tool,secretCode,validAccount));
    }

    function getHashForUniqueGame(address primary, address secondary) public view isActiveContract returns (bytes32 hashResult) {
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
}