package nz.ac.auckland.se281.engine;

import java.util.ArrayList;
import java.util.List;
import nz.ac.auckland.se281.model.Colour;

public class RandomStrategy implements Strategy {

  @Override
  public List<Colour> getAiColours(List<Colour> playerPicks) {
    List<Colour> aiColours = new ArrayList<>();
    // generate two random colours for the ai
    for (int i = 0; i < 2; i++) {
      aiColours.add(Colour.getRandomColourForAi());
    }
    return aiColours;
  }
}
