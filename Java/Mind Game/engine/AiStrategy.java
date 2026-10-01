package nz.ac.auckland.se281.engine;

import java.util.List;
import nz.ac.auckland.se281.model.Colour;

public class AiStrategy {

  private Strategy strategy;
  private final List<Colour> playerPicks;

  public AiStrategy(List<Colour> playerPicks, Strategy strategy) {
    this.playerPicks = playerPicks;
    this.strategy = strategy;
  }

  public void setStrategy(Strategy newStrategy) {
    this.strategy = newStrategy;
  }

  public Strategy getCurrentStrategy() {
    return this.strategy;
  }

  public List<Colour> getAiPicks() {
    return strategy.getAiColours(this.playerPicks);
  }
}
