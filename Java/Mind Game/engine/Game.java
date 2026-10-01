package nz.ac.auckland.se281.engine;

import java.util.ArrayList;
import java.util.List;
import nz.ac.auckland.se281.Main.Difficulty;
import nz.ac.auckland.se281.cli.MessageCli;
import nz.ac.auckland.se281.cli.Utils;
import nz.ac.auckland.se281.model.Colour;

public class Game {
  // Enemy #1
  public static String AI_NAME = "HAL-9000";

  // Constants
  AI ai;
  private int numRounds;
  private String playerName;

  // Dynamic Variables
  private int currentRound;
  private int scorePlayer;
  private int scoreAi;
  private boolean didAiWin;
  private boolean gameStarted;
  private List<Colour> playerPrevPicks = new ArrayList<>();

  public Game() {}

  public void newGame(Difficulty difficulty, int numRounds, String[] options) {
    this.playerName = options[0];
    this.numRounds = numRounds;
    this.ai = new AI.Builder(difficulty).build();

    // reset
    this.currentRound = 1;
    this.scorePlayer = 0;
    this.scoreAi = 0;
    this.didAiWin = false;
    this.playerPrevPicks.clear();

    this.gameStarted = true;

    MessageCli.WELCOME_PLAYER.printMessage(this.playerName);
  }

  public void play() {
    if (!this.gameStarted) {
      MessageCli.GAME_NOT_STARTED.printMessage();
      return;
    }

    Colour powerColour;
    int newPointsPlayer = 0;
    int newPointsAi = 0;

    MessageCli.START_ROUND.printMessage(this.currentRound, this.numRounds);

    // index: 0 = Player's own colour   index: 1 = player's guess
    List<Colour> playerColours = getPlayerColours();
    List<Colour> aiColours =
        this.ai.getPicks(this.currentRound, this.playerPrevPicks, this.didAiWin);

    MessageCli.PRINT_INFO_MOVE.printMessage(Game.AI_NAME, aiColours.get(0), aiColours.get(1));
    MessageCli.PRINT_INFO_MOVE.printMessage(
        this.playerName, playerColours.get(0), playerColours.get(1));

    // assigning points
    if (playerColours.get(1).equals(aiColours.get(0))) {
      newPointsPlayer++;
    }
    if (playerColours.get(0).equals(aiColours.get(1))) {
      newPointsAi++;
      this.didAiWin = true;
    } else {
      this.didAiWin = false;
    }

    if (this.currentRound % 3 == 0) {
      powerColour = Colour.getRandomColourForPowerColour();
      MessageCli.PRINT_POWER_COLOUR.printMessage(powerColour);

      if (playerColours.get(1).equals(powerColour) && newPointsPlayer > 0) {
        newPointsPlayer += 2;
      }
      if (aiColours.get(1).equals(powerColour) && newPointsAi > 0) {
        newPointsAi += 2;
      }
    }

    MessageCli.PRINT_OUTCOME_ROUND.printMessage(Game.AI_NAME, newPointsAi);
    MessageCli.PRINT_OUTCOME_ROUND.printMessage(this.playerName, newPointsPlayer);
    this.scorePlayer += newPointsPlayer;
    this.scoreAi += newPointsAi;

    if (this.currentRound == this.numRounds) {
      showStats();
      MessageCli.PRINT_END_GAME.printMessage();
      if (this.scorePlayer > this.scoreAi) {
        MessageCli.PRINT_WINNER_GAME.printMessage(this.playerName);
      } else if (this.scoreAi > this.scorePlayer) {
        MessageCli.PRINT_WINNER_GAME.printMessage(Game.AI_NAME);
      } else {
        MessageCli.PRINT_TIE_GAME.printMessage();
      }
      this.gameStarted = false;
      return;
    }

    this.playerPrevPicks.add(playerColours.get(0));
    this.currentRound++;
  }

  public void showStats() {
    if (this.gameStarted) {
      MessageCli.PRINT_PLAYER_POINTS.printMessage(Game.AI_NAME, this.scoreAi);
      MessageCli.PRINT_PLAYER_POINTS.printMessage(this.playerName, this.scorePlayer);
    } else {
      MessageCli.GAME_NOT_STARTED.printMessage();
    }
  }

  // Helper Functions
  private List<Colour> getPlayerColours() {
    String[] inputs;

    while (true) {
      MessageCli.ASK_HUMAN_INPUT.printMessage();
      inputs = Utils.scanner.nextLine().split("\\s+");

      // check if there is only 2 inputs
      if (inputs.length != 2) {
        MessageCli.INVALID_HUMAN_INPUT.printMessage();
        continue;
      }

      // get colours
      Colour playerColour = Colour.fromInput(inputs[0]);
      Colour playerGuess = Colour.fromInput(inputs[1]);

      // check the colours entered are valid colours
      if (playerColour == null || playerGuess == null) {
        MessageCli.INVALID_HUMAN_INPUT.printMessage();
        continue;
      }

      // package results into an array to be returned
      List<Colour> playerColours = new ArrayList<>();
      playerColours.add(playerColour);
      playerColours.add(playerGuess);

      return playerColours;
    }
  }
}
