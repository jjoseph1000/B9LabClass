pragma solidity ^0.4.6;

import "./ActiveState.sol";

contract RockPaperScissors is ActiveState {
    mapping (uint => mapping(uint => uint)) winnerDetermination;
    enum ToolChoice {
        notool,
        rock,
        paper,        
        scissors
    }

    function RockPaperScissors(bool _isActive) ActiveState(_isActive) public {
        /*  Determine who wins user or opponent
            0=tie, 1=user, 2=opponent  */
        winnerDetermination[uint(ToolChoice.rock)][uint(ToolChoice.rock)] = 0;
        winnerDetermination[uint(ToolChoice.rock)][uint(ToolChoice.scissors)] = 1;
        winnerDetermination[uint(ToolChoice.rock)][uint(ToolChoice.paper)] = 2;
        winnerDetermination[uint(ToolChoice.scissors)][uint(ToolChoice.rock)] = 2;
        winnerDetermination[uint(ToolChoice.scissors)][uint(ToolChoice.scissors)] = 0;
        winnerDetermination[uint(ToolChoice.scissors)][uint(ToolChoice.paper)] = 1;
        winnerDetermination[uint(ToolChoice.paper)][uint(ToolChoice.rock)] = 1;
        winnerDetermination[uint(ToolChoice.paper)][uint(ToolChoice.scissors)] = 2;
        winnerDetermination[uint(ToolChoice.paper)][uint(ToolChoice.paper)] = 0;
    }

    event LogPickHiddenTool(bytes32 hashedGameId, address player, bytes32 hiddenToolChoice, uint amount, uint gameProgression, uint gameDeadline);
    event LogRevealHiddenTool(bytes32 hashedGameId, address player, uint toolChoice);
    event LogGameProgression(bytes32 hashedGameId, uint gameProgression, uint gameDeadline);
    event LogAllocatedFundsToWinner(address player, uint playerAmount, address opponent, uint opponentAmount);
    event LogResetGame(bytes32 hashedGameId);
    event LogFundDistributionFromForfeitedGame(address player, uint playerAmount, address opponent, uint opponentAmount);
    event LogClaimWinnings(address player, uint amount);

    enum GameProgression {
        NoToolsSelected,
        OnePlayerPickedHiddenTool,
        BothPlayersPickedHiddenTool,
        OnePlayerRevealedTool
    }

    struct Player {
        bytes32 hiddenToolChoice;
        uint toolChoice;
        uint amount;
    }

    struct Game {
        mapping (address => Player) playerChoice;
        GameProgression gameProgression;
        uint gameDeadline;
    }

    mapping (bytes32 => Game) rockPaperScissorsGame;
    mapping (address => uint) winnings;
    mapping (address => mapping(bytes32 => bool)) usedSecretCodes;
    uint gameDeadlineLength = 40320;

    function getGameProgression(address user, address opponent, string gameKeyword) public isActiveContract view 
        returns (bytes32 hashValue, uint gameProgression) {
        hashValue = getHashForUniqueGame(user,opponent,gameKeyword);
        Game storage gameRecord = rockPaperScissorsGame[hashValue];
        return (hashValue, uint(gameRecord.gameProgression));
    }
    /*
        User will pick opponent they want to play against and submit their tool as hidden hash value.
     */

    function pickHiddenTool(address opponent, bytes32 hiddenTool, string gameKeyword, uint amountToWagerFromPreviousWinnings) public isActiveContract payable returns (bool success) {
        require(opponent != address(0));
        //  They may elect to wager ether from their previous winnings to this game.
        require(amountToWagerFromPreviousWinnings <= winnings[msg.sender]);
        uint totalToWager = amountToWagerFromPreviousWinnings + msg.value;
        require(totalToWager > 0);
        winnings[msg.sender] -= amountToWagerFromPreviousWinnings;

        // Previous secret code and tool combo cannnot be used again.
        require(usedSecretCodes[msg.sender][hiddenTool] == false);

        // All games between two accounts will have a unique hash value for identification purposes.
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent,gameKeyword);
        Game storage gameRecord = rockPaperScissorsGame[hashValue];
        require(gameRecord.gameProgression == GameProgression.NoToolsSelected || gameRecord.gameProgression == GameProgression.OnePlayerPickedHiddenTool);
        require(gameRecord.gameDeadline > block.number || gameRecord.gameProgression == GameProgression.NoToolsSelected);

        // Tool choice will be saved in hash form.
        gameRecord.playerChoice[msg.sender].hiddenToolChoice = hiddenTool;
        gameRecord.playerChoice[msg.sender].amount = totalToWager;   

        if (gameRecord.playerChoice[opponent].hiddenToolChoice == 0x0)
        {
            gameRecord.gameProgression = GameProgression.OnePlayerPickedHiddenTool;
        }
        else
        {
            gameRecord.gameProgression = GameProgression.BothPlayersPickedHiddenTool;
        }

        if (gameRecord.gameDeadline == 0)
        {
            gameRecord.gameDeadline = block.number + gameDeadlineLength;
        }

        usedSecretCodes[msg.sender][hiddenTool] = true;

        LogPickHiddenTool(hashValue, msg.sender, hiddenTool, totalToWager, uint(gameRecord.gameProgression),gameRecord.gameDeadline);

        return (true);
    }

    /*
        Using thier secret code, their tool is revealed and saved.   If the player is the second to reveal
        then the determination will be made as to who won and their account will be credited  with all the ether 
        and the unique game will reset.
     */
    function revealHiddenTool(address opponent, string secretCode, uint revealedTool, string gameKeyword) public isActiveContract returns (bool success) {
        require(opponent != address(0));
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent,gameKeyword);
        Game storage gameRecord = rockPaperScissorsGame[hashValue];
        require(gameRecord.gameProgression == GameProgression.BothPlayersPickedHiddenTool || gameRecord.gameProgression == GameProgression.OnePlayerRevealedTool);
        require(gameRecord.gameDeadline > block.number);
        require(revealedTool >= 1 && revealedTool <= 3);

        bytes32 hiddenToolChoice = gameRecord.playerChoice[msg.sender].hiddenToolChoice;
        if (getHashForSecretlyPickingTool(revealedTool,secretCode)==hiddenToolChoice)
        {
            gameRecord.playerChoice[msg.sender].toolChoice = revealedTool;
        }
        else
        {
            revert();
        }
        
        LogRevealHiddenTool(hashValue, msg.sender, uint(gameRecord.playerChoice[msg.sender].toolChoice));

        if (gameRecord.gameProgression == GameProgression.BothPlayersPickedHiddenTool)
        {
            gameRecord.gameProgression = GameProgression.OnePlayerRevealedTool;
            LogGameProgression(hashValue, uint(gameRecord.gameProgression), gameRecord.gameDeadline);
        }
        else
        {
            uint toolChoice = gameRecord.playerChoice[msg.sender].toolChoice;
            uint opponentToolChoice = gameRecord.playerChoice[opponent].toolChoice;
            uint playerWinnings=0;
            uint opponentWinnings=0;

            uint gameResult = winnerDetermination[toolChoice][opponentToolChoice];
            if (gameResult==1)
            {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount + gameRecord.playerChoice[opponent].amount;
            }
            else if (gameResult==0)
            {
                    playerWinnings = gameRecord.playerChoice[msg.sender].amount;
                    opponentWinnings = gameRecord.playerChoice[opponent].amount;
            }
            else if (gameResult==2)
            {
                    opponentWinnings = gameRecord.playerChoice[msg.sender].amount + gameRecord.playerChoice[opponent].amount;
            }

            winnings[msg.sender] += playerWinnings;
            winnings[opponent] += opponentWinnings;
            LogAllocatedFundsToWinner(msg.sender, playerWinnings, opponent, opponentWinnings);

            resetGame(opponent,gameKeyword);         
        }

        return (true);
    }

    function resetGame(address opponent, string gameKeyword) public returns (bool success) {
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent,gameKeyword);
        Game storage gameRecord = rockPaperScissorsGame[hashValue];
        
        gameRecord.gameProgression = GameProgression.NoToolsSelected;
        gameRecord.gameDeadline = 0;
        gameRecord.playerChoice[msg.sender].hiddenToolChoice = 0x0;
        gameRecord.playerChoice[msg.sender].toolChoice = uint(ToolChoice.notool);
        gameRecord.playerChoice[msg.sender].amount = 0;
        gameRecord.playerChoice[opponent].hiddenToolChoice = 0x0;
        gameRecord.playerChoice[opponent].toolChoice = uint(ToolChoice.notool);
        gameRecord.playerChoice[opponent].amount = 0;
        LogResetGame(hashValue);

        return (true);
    }

    function claimFundsFromForfeitedGame(address opponent, string gameKeyword) public isActiveContract returns (bool success) {
        require(opponent != address(0));
        bytes32 hashValue = getHashForUniqueGame(msg.sender,opponent,gameKeyword);
        Game storage gameRecord = rockPaperScissorsGame[hashValue];
        require(gameRecord.gameDeadline > 0 && gameRecord.gameDeadline < block.number);

        /* Any period before one player reveals their tool will result in both players receiving their funds back.
           If one player has already revealed their tool then that player will be entitled to all 
           funds from the game  */
        uint playerAmount=0;
        uint opponentAmount=0;
        if (gameRecord.gameProgression == GameProgression.OnePlayerRevealedTool)
        {
            if (gameRecord.playerChoice[opponent].toolChoice == uint(ToolChoice.notool))
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

        resetGame(opponent,gameKeyword);

        return (true);
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
    function getHashForSecretlyPickingTool(uint tool, string secretCode) public isActiveContract returns (bytes32 hashResult) {
        require(tool>=1&&tool<=3);

        return (keccak256(tool,secretCode));
    }

    function getHashForUniqueGame(address primary, address secondary, string gameKeyword) public view isActiveContract returns (bytes32 hashResult) {
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


        return (keccak256(firstAddress,secondAddress,gameKeyword));
    }    
}