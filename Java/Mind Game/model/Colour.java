package nz.ac.auckland.se281.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import nz.ac.auckland.se281.cli.Utils;

/** You cannot modify this class! */
public enum Colour {
  RED,
  GREEN,
  BLUE,
  YELLOW;

  public static Colour getRandomColourExcluding(Colour exclude) {
    List<Colour> options = new ArrayList<>(List.of(values()));
    options.remove(exclude);

    int index = Utils.randomAi.nextInt(options.size());
    return options.get(index);
  }

  public static Colour getRandomColourForAi() {
    return getRandomColour(Utils.randomAi);
  }

  public static Colour getRandomColourForPowerColour() {
    return getRandomColour(Utils.randomPowerNumber);
  }

  private static Colour getRandomColour(Random random) {
    Colour[] allColours = values();
    int index = random.nextInt(allColours.length);
    return allColours[index];
  }

  public static Colour fromInput(String input) {

    if (input == null) {
      return null; // I put null because we did not cover Exceptions yet (it would be better to
      // use exception here :) ) but keep null for simplicity.
    }

    input = input.trim().toUpperCase();

    switch (input) {
      case "R":
      case "RED":
        return RED;
      case "G":
      case "GREEN":
        return GREEN;
      case "B":
      case "BLUE":
        return BLUE;
      case "Y":
      case "YELLOW":
        return YELLOW;
      default:
        return null; // I put null because we did not cover Exceptions yet (it would be better to
        // use exception here :) ) but keep null for simplicity.
    }
  }
}
