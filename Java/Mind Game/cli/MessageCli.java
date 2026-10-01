package nz.ac.auckland.se281.cli;

/** You cannot modify this class! */
public enum MessageCli {
  // Already implemented for you; do not use these in your own code
  COMMAND_NOT_FOUND(
      "Error! Command not found. (Run 'help' to see the list of available commands): \"%s\""),
  WRONG_ARGUMENT_COUNT(
      "Error! Incorrect number of arguments. Expected %s argument%s for the \"%s\" command."),
  NO_COMMAND("Error! No command entered."),
  END("You closed the terminal, Goodbye!"),
  INVALID_DIFFICULTY("Error! Invalid difficulty level. Valid options are EASY, MEDIUM, and HARD."),
  INVALID_ROUNDS("Error! The number of rounds must be a positive integer greater than 0."),
  // The following messages are intended for use in your implementation
  ASK_HUMAN_INPUT(
      "Enter two colors (RED, GREEN, BLUE, YELLOW): your own color followed by your guess, then"
          + " press Enter."),
  INVALID_HUMAN_INPUT(
      "Error! Invalid input. Allowed colors are RED, GREEN, BLUE, and YELLOW (you may also use R,"
          + " G, B, or Y). Please try again."),
  GAME_NOT_STARTED("Error! Game not started yet. Please start a new game first."),
  WELCOME_PLAYER("Welcome, %s!"),
  START_ROUND("Starting round %s of %s:"),
  PRINT_INFO_MOVE("Player %s: chose %s and guessed %s"),
  PRINT_POWER_COLOUR("The POWER COLOUR is %s!"),
  PRINT_OUTCOME_ROUND("Player %s earned %s point(s) this round."),
  PRINT_PLAYER_POINTS("Player %s has %s point(s)."),
  PRINT_END_GAME("The game is over!"),
  PRINT_WINNER_GAME("Player %s wins the game!"),
  PRINT_TIE_GAME("It's a tie! Both players have the same number of points.");

  private final String msg;

  private MessageCli(final String msg) {
    this.msg = msg;
  }

  public String getMessage(final Object... args) {
    String tmpMessage = msg;
    for (final Object arg : args) {
      tmpMessage = tmpMessage.replaceFirst("%s", String.valueOf(arg));
    }
    return tmpMessage;
  }

  public void printMessage(final Object... args) {
    System.out.println(getMessage(args));
  }

  @Override
  public String toString() {
    return msg;
  }
}
