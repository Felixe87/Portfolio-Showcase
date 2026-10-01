package nz.ac.auckland.se281.engine;

import java.util.ArrayList;
import java.util.List;
import nz.ac.auckland.se281.model.Colour;

public class AvoidLastStrategy implements Strategy {

  @Override
  public List<Colour> getAiColours(List<Colour> playerPicks) {
    List<Colour> aiColours = new ArrayList<>();

    aiColours.add(Colour.getRandomColourForAi());
    // get latest move (aka: the previous move)
    aiColours.add(Colour.getRandomColourExcluding(playerPicks.get(playerPicks.size() - 1)));

    return aiColours;
  }
}
