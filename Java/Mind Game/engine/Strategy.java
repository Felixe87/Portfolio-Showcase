package nz.ac.auckland.se281.engine;

import java.util.List;
import nz.ac.auckland.se281.model.Colour;

public interface Strategy {

  List<Colour> getAiColours(List<Colour> playerPicks);
}
