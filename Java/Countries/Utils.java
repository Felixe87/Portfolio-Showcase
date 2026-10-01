package nz.ac.auckland.se281;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

/**
 * Utility methods for common tasks.
 *
 * <p>CANNOT CHANGE EXISTING METHODS BUT YOU CAN ADD NEW ONES.
 */
public class Utils {

  public static Scanner scanner = new Scanner(System.in);

  public static List<String> readCountries() {
    return readCsv("./src/main/resources/countries.csv");
  }

  public static List<String> readAdjacencies() {
    return readCsv("./src/main/resources/adjacencies.csv");
  }

  /**
   * read the content of a csv file.
   *
   * @param fileName of the csv file.
   * @return a list of String, where each element is a line in the CSV file.
   */
  private static List<String> readCsv(String fileName) {
    List<String> result = new LinkedList<>();

    String line;
    try (BufferedReader br = new BufferedReader(new FileReader(fileName))) {
      while ((line = br.readLine()) != null) { // until the file has lines
        result.add(line);
      }
    } catch (IOException e) {
      e.printStackTrace();
    }

    return result;
  }

  /**
   * Capitalise the first letter of each word Example: "hello world" -> "Hello World".
   *
   * @param input the string to process.
   * @return the input string with all words with first letter capitalised.
   */
  public static String capitalizeFirstLetterOfEachWord(String input) {
    if (input == null || input.isEmpty()) {
      return input; // Return the input if it's null or empty
    }

    String[] words = input.split("\\s+"); // Split the string by whitespace
    StringBuilder capitalizedString = new StringBuilder();

    for (String word : words) {
      if (!word.isEmpty()) {
        char firstChar = Character.toUpperCase(word.charAt(0));
        String restOfString = word.length() > 1 ? word.substring(1) : "";
        capitalizedString.append(firstChar).append(restOfString).append(" ");
      }
    }
    // Remove the trailing space
    return capitalizedString.toString().trim();
  }

  /**
   * Asks user for a country name, and checks if it is inside the graph. Throws my custom exception.
   *
   * @param countryGraph the graph to check for a key matching the input
   * @return the input string but formatted to how they key is
   */
  public static String getValidCountryName(Graph countryGraph) throws InvalidCountryName {
    String input = capitalizeFirstLetterOfEachWord(scanner.nextLine());
    if (!countryGraph.containsCountry(input)) {
      throw new InvalidCountryName(input);
    }
    return input;
  }

  /**
   * Converts the map I use specifically to store all of the continents into a formatted String.
   *
   * @param map HashMap of continent name and fuel cost.
   * @return formatted String.
   */
  public static String convertMapToString(Map<String, Integer> map) {
    StringBuilder stringifiedMap = new StringBuilder();
    stringifiedMap.append("["); // start the string

    // so I can keep track of how many we're doing
    Iterator<Map.Entry<String, Integer>> iterator = map.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<String, Integer> entry = iterator.next();
      stringifiedMap.append(entry.getKey()).append(" (").append(entry.getValue()).append(")");

      // so we can avoid a trailing ,
      if (iterator.hasNext()) {
        stringifiedMap.append(", ");
      }
    }

    // finish and return
    stringifiedMap.append("]");
    return stringifiedMap.toString();
  }
}
