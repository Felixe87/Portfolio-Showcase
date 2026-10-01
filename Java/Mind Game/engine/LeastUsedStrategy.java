package nz.ac.auckland.se281.engine;

import java.util.ArrayList;
import java.util.List;
import nz.ac.auckland.se281.model.Colour;

public class LeastUsedStrategy implements Strategy {

  @Override
  public List<Colour> getAiColours(List<Colour> playerPicks) {
    Colour[] allColours = Colour.values();
    int[] count = {0, 0, 0, 0};

    // count every colour in the list
    for (Colour c : playerPicks) {
      switch (c) {
        case Colour.RED:
          count[0] += 1;
          break;
        case Colour.GREEN:
          count[1] += 1;
          break;
        case Colour.BLUE:
          count[2] += 1;
          break;
        case Colour.YELLOW:
          count[3] += 1;
      }
    }

    // find the index of the colour with the lowest count (biased towards the first lowest in the
    // list)
    int lowestIndex = 0;
    for (int i = 1; i < 4; i++) {
      if (count[i] < count[lowestIndex]) {
        lowestIndex = i;
      }
    }

    // assemble ai picks, with the lowest occuring pick being it's guess
    List<Colour> aiColours = new ArrayList<>();
    aiColours.add(Colour.getRandomColourForAi());
    aiColours.add(allColours[lowestIndex]);
    return aiColours;
  }
}
