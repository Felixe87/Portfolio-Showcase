package nz.ac.auckland.se281.engine;

import java.util.List;
import nz.ac.auckland.se281.Main.Difficulty;
import nz.ac.auckland.se281.model.Colour;

public class AI {

  private final Difficulty difficulty;
  private Strategy prevStrategy;

  private AI(Builder builder) {
    this.difficulty = builder.difficulty;
  }

  public List<Colour> getPicks(int round, List<Colour> playerPicks, boolean didWeWin) {
    AiStrategy strat = new AiStrategy(playerPicks, new RandomStrategy());

    switch (this.difficulty) {
      case Difficulty.EASY:
        break; // no need to change strategy
      case Difficulty.MEDIUM:
        if (round > 1) {
          strat.setStrategy(new AvoidLastStrategy());
        }
        break;
      case Difficulty.HARD:
        if (round > 3) {
          // any round after 3
          // continue using winning strat
          strat.setStrategy(this.prevStrategy);
          // unless
          if (!didWeWin && this.prevStrategy instanceof AvoidLastStrategy) {
            // ai lost, check if the prev strat was AvoidLast
            strat.setStrategy(new LeastUsedStrategy());
          } else if (!didWeWin) {
            // if it wasn't AvoidLast then it must've been LeastUsed
            strat.setStrategy(new AvoidLastStrategy());
          }
        } else if (round == 3) {
          // only round 3
          strat.setStrategy(new LeastUsedStrategy());
        }
    }

    this.prevStrategy = strat.getCurrentStrategy();
    return strat.getAiPicks();
  }

  // Builds the AI with the current difficulty set
  public static class Builder {
    private Difficulty difficulty;

    public Builder(Difficulty newDifficulty) {
      this.difficulty = newDifficulty;
    }

    public AI build() {
      return new AI(this);
    }
  }
}
