pragma solidity ^0.4.6;

import "./ActiveState.sol";

contract RockPaperScissors is ActiveState {
    function RockPaperScissors(bool _isActive) ActiveState(_isActive) public {
    }

    event LogPickHiddenTool(bytes32 hashedGameId, address player, bytes32 hiddenToolChoice, uint amount, uint gameProgression, uint gameDeadline);
    event LogRevealHiddenTool(bytes32 hashedGameId, address player, uint toolChoice);
    event LogGameProgression(bytes32 hashedGameId, uint gameProgression, uint gameDeadline);
    event LogAllocatedFundsToWinner(address player, uint playerAmount, address opponent, uint opponentAmount);
    event LogResetGame(bytes32 hashedGameId);
    event LogFundDistributionFromForfeitedGame(address player, uint playerAmount, address opponent, uint opponentAmount);
    event LogClaimWinnings(address player, uint amount);

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
        uint gameDeadline;
    }

    mapping (bytes32 => rockPaperScissorsGameStruct) rockPaperScissorsGame;
    mapping (address => uint) winnings;
    uint gameDeadlineLength = 40320;

    function getGameProgression(address opponent) public isActiveContract view returns (uint gameProgression, address, bytes32,  address, bytes32) {
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        rockPaperScissorsGameStruct storage gameRecord = rockPaperScissorsGame[hashValue];
        return (uint(gameRecord.gameProgression),msg.sender,gameRecord.playerChoice[msg.sender].hiddenToolChoice,opponent,gameRecord.playerChoice[opponent].hiddenToolChoice);
    }
    /*
        User will pick opponent they want to play against and submit their tool as hidden hash value.
     */

    function pickHiddenTool(address opponent, bytes32 hiddenTool) public isActiveContract payable returns (bool success) {
        require(opponent != address(0));

        //  The total of their previous winnings + ether submitted must be greater than nothing to play.
        uint totalToWager = winnings[msg.sender] + msg.value;
        require(totalToWager > 0);

        // All games between two accounts will have a unique hash value for identification purposes.
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        rockPaperScissorsGameStruct storage gameRecord = rockPaperScissorsGame[hashValue];
        require(gameRecord.gameProgression < GameProgression.BothPlayersPickedHiddenTool);
        require(gameRecord.gameDeadline > block.number || gameRecord.gameProgression == GameProgression.NoToolsSelected);

        // Tool choice will be saved in hash form.
        gameRecord.playerChoice[msg.sender].hiddenToolChoice = hiddenTool;
        gameRecord.playerChoice[msg.sender].amount = totalToWager;   
        // Zero out balance since it will be used in current game.
        winnings[msg.sender] = 0;

        if (gameRecord.playerChoice[opponent].hiddenToolChoice == 0x0)
        {
            gameRecord.gameProgression = GameProgression.OnePlayerPickedHiddenTool;
        }
        else
        {
            gameRecord.gameProgression = GameProgression.BothPlayersPickedHiddenTool;
        }
        gameRecord.gameDeadline = block.number + gameDeadlineLength;

        LogPickHiddenTool(hashValue, msg.sender, hiddenTool, totalToWager, uint(gameRecord.gameProgression),gameRecord.gameDeadline);

        return (true);
    }

    /*
        Using thier secret code, their tool is revealed and saved.   If the player is the second to reveal
        then the determination will be made as to who won and their account will be credited  with all the ether 
        and the unique game will reset.
     */
    function revealHiddenTool(address opponent, string secretCode) public isActiveContract returns (bool success) {
        require(opponent != address(0));
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        rockPaperScissorsGameStruct storage gameRecord = rockPaperScissorsGame[hashValue];
        require(gameRecord.gameProgression == GameProgression.BothPlayersPickedHiddenTool || gameRecord.gameProgression == GameProgression.OnePlayerRevealedTool);
        require(gameRecord.gameDeadline > block.number);

        bytes32 hiddenToolChoice = gameRecord.playerChoice[msg.sender].hiddenToolChoice;
        if (getHashForSecretlyPickingTool(1,secretCode)==hiddenToolChoice)
        {
            gameRecord.playerChoice[msg.sender].toolChoice = ToolChoice.rock;
        }
        else if (getHashForSecretlyPickingTool(2,secretCode)==hiddenToolChoice)
        {
            gameRecord.playerChoice[msg.sender].toolChoice = ToolChoice.scissors;
        }
        else if (getHashForSecretlyPickingTool(3,secretCode)==hiddenToolChoice)
        {
            gameRecord.playerChoice[msg.sender].toolChoice = ToolChoice.paper;
        }
        else
        {
            revert();
        }

        LogRevealHiddenTool(hashValue, msg.sender, uint(gameRecord.playerChoice[msg.sender].toolChoice));

        if (gameRecord.gameProgression == GameProgression.BothPlayersPickedHiddenTool)
        {
            gameRecord.gameProgression = GameProgression.OnePlayerRevealedTool;
            gameRecord.gameDeadline = block.number + gameDeadlineLength;
            LogGameProgression(hashValue, uint(gameRecord.gameProgression), gameRecord.gameDeadline);
        }
        else
        {
            ToolChoice toolChoice = gameRecord.playerChoice[msg.sender].toolChoice;
            ToolChoice opponentToolChoice = gameRecord.playerChoice[opponent].toolChoice;
            uint playerWinnings;
            uint opponentWinnings;

            if (toolChoice == ToolChoice.rock)
            {
                if (opponentToolChoice == ToolChoice.rock)
                {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount;
                    opponentWinnings = gameRecord.playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.scissors)
                {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.paper)
                {
                    opponentWinnings = gameRecord.playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
            }
            else if (toolChoice == ToolChoice.scissors)
            {
                if (opponentToolChoice == ToolChoice.rock)
                {
                    opponentWinnings = gameRecord.playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.scissors)
                {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount;
                    opponentWinnings = gameRecord.playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.paper)
                {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
            }
            else if (toolChoice == ToolChoice.paper)
            {
                if (opponentToolChoice == ToolChoice.rock)
                {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.scissors)
                {
                    opponentWinnings = gameRecord.playerChoice[msg.sender].amount + rockPaperScissorsGame[hashValue].playerChoice[opponent].amount;
                }
                else if (opponentToolChoice == ToolChoice.paper)
                {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount;
                    opponentWinnings = gameRecord.playerChoice[opponent].amount;
                }
            }

            winnings[msg.sender] += playerWinnings;
            winnings[opponent] += opponentWinnings;
            LogAllocatedFundsToWinner(msg.sender, playerWinnings, opponent, opponentWinnings);

            ResetGame(opponent);         
        }

        return (true);
    }

    function ResetGame(address opponent) public returns (bool success) {
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        rockPaperScissorsGameStruct storage gameRecord = rockPaperScissorsGame[hashValue];
        
        gameRecord.gameProgression = GameProgression.NoToolsSelected;
        gameRecord.gameDeadline = 0;
        gameRecord.playerChoice[msg.sender].hiddenToolChoice = 0x0;
        gameRecord.playerChoice[msg.sender].toolChoice = ToolChoice.notool;
        gameRecord.playerChoice[msg.sender].amount = 0;
        gameRecord.playerChoice[opponent].hiddenToolChoice = 0x0;
        gameRecord.playerChoice[opponent].toolChoice = ToolChoice.notool;
        gameRecord.playerChoice[opponent].amount = 0;
        LogResetGame(hashValue);

        return (true);
    }

    function claimFundsFromForfeitedGame(address opponent) public isActiveContract returns (bool success) {
        require(opponent != address(0));
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent);
        rockPaperScissorsGameStruct storage gameRecord = rockPaperScissorsGame[hashValue];
        require(gameRecord.gameDeadline > 0 && gameRecord.gameDeadline < block.number);

        /* Any period before one player reveals their tool will result in both players receiving their funds back.
           If one player has already revealed their tool then that player will be entitled to all 
           funds from the game  */
        uint playerAmount;
        uint opponentAmount;
        if (gameRecord.gameProgression == GameProgression.OnePlayerRevealedTool)
        {
            if (gameRecord.playerChoice[opponent].toolChoice == ToolChoice.notool)
            {
                playerAmount = gameRecord.playerChoice[msg.sender].amount + gameRecord.playerChoice[opponent].amount;
            }
            else
            {
                opponentAmount = gameRecord.playerChoice[msg.sender].amount + gameRecord.playerChoice[opponent].amount;
            }
        }
        else
        {
            playerAmount = gameRecord.playerChoice[msg.sender].amount;
            opponentAmount = gameRecord.playerChoice[opponent].amount;
        }

        winnings[msg.sender] += playerAmount;
        winnings[opponent] += opponentAmount;

        LogFundDistributionFromForfeitedGame(msg.sender, playerAmount, opponent, opponentAmount);

        ResetGame(opponent);
    }

    function balanceOf(address player) public isActiveContract view returns (uint amount) {
        return (winnings[player]);
    }

    function claimWinnings() public isActiveContract returns (bool success) {
        require(winnings[msg.sender] > 0);

        uint winningProceeds = winnings[msg.sender];
        winnings[msg.sender] = 0;
        LogClaimWinnings(msg.sender, winningProceeds);
        msg.sender.transfer(winningProceeds);

        return (true);
    }

    /* Used for hashing the tool preference for game  */
    function getHashForSecretlyPickingTool(uint tool, string secretCode) public view isActiveContract returns (bytes32 hashResult) {
        return (keccak256(tool,secretCode));
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