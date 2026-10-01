package nz.ac.auckland.se281;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Set;

/** This class is the main entry point. */
public class MapEngine {

  private Graph countryGraph;

  public MapEngine() {
    this.countryGraph = new Graph();
    loadMap();
  }

  /** invoked one time only when constracting the MapEngine class. */
  private void loadMap() {
    List<String> countries = Utils.readCountries();
    List<String> adjacencies = Utils.readAdjacencies();

    // parse country data
    for (String entry : countries) {
      String[] parts = entry.split(",");
      String name = parts[0];
      String continent = parts[1];
      int fuelCost = Integer.parseInt(parts[2]);
      countryGraph.addCountry(name, continent, fuelCost);
    }

    // parse neighbor data
    for (String entry : adjacencies) {
      String[] parts = entry.split(",");
      String country = parts[0];
      for (int i = 1; i < parts.length; i++) {
        countryGraph.addEdge(country, parts[i]);
      }
    }
  }

  /** this method is invoked when the user run the command info-country. */
  public void showInfoCountry() {
    String input = null;

    // get a valid country as the input
    MessageCli.INSERT_COUNTRY.printMessage();
    while (input == null) {
      try {
        input = Utils.getValidCountryName(countryGraph);
      } catch (InvalidCountryName e) {
        System.out.println(e.getMessage());
      }
    }

    MessageCli.COUNTRY_INFO.printMessage(
        input,
        countryGraph.getContinent(input),
        Integer.toString(countryGraph.getFuelCost(input)),
        countryGraph.getNeighbors(input).toString());
  }

  /** this method is invoked when the user run the command route. */
  public void showRoute() {
    String origin = null;
    String destination = null;

    // get a valid country as the starting country
    MessageCli.INSERT_SOURCE.printMessage();
    while (origin == null) {
      try {
        origin = Utils.getValidCountryName(countryGraph);
      } catch (InvalidCountryName e) {
        System.out.println(e.getMessage());
      }
    }
    // get a valid country for the destination
    MessageCli.INSERT_DESTINATION.printMessage();
    while (destination == null) {
      try {
        destination = Utils.getValidCountryName(countryGraph);
      } catch (InvalidCountryName e) {
        System.out.println(e.getMessage());
      }
    }
    // if the destination is the origin print custom message
    if (origin.equals(destination)) {
      MessageCli.NO_CROSSBORDER_TRAVEL.printMessage();
      return;
    }

    List<String> countryPath = getShortestRoute(origin, destination);
    Map<String, Integer> continentPath = new LinkedHashMap<>();
    int totalFuelSpent = 0;

    // getting fuel data stats
    for (int i = 0; i < countryPath.size(); i++) {
      int fuelCost = 0; // used in code later
      // get the fuel spent to reach destination, excluding first and last entries
      if (!(i == 0 || i == countryPath.size() - 1)) {
        fuelCost = countryGraph.getFuelCost(countryPath.get(i));
        totalFuelSpent += fuelCost;
      }
      // get the number of continents visited, and fuel in each
      String continent = countryGraph.getContinent(countryPath.get(i));
      continentPath.put(continent, continentPath.getOrDefault(continent, 0) + fuelCost);
    }

    // get most expensive continent
    // normally I wouldn't use min_value but the opportunity to use a LinkedHashMap was too good
    int mostFuelSpentInContenent = Integer.MIN_VALUE;
    String mostExpensiveContinent = null;
    for (Map.Entry<String, Integer> entry : continentPath.entrySet()) {
      int fuelSpentInContinent = entry.getValue();
      if (fuelSpentInContinent > mostFuelSpentInContenent) {
        mostFuelSpentInContenent = fuelSpentInContinent;
        mostExpensiveContinent = entry.getKey();
      }
    }

    // print results and stats about route
    MessageCli.ROUTE_INFO.printMessage(countryPath.toString());
    MessageCli.FUEL_INFO.printMessage(Integer.toString(totalFuelSpent));
    MessageCli.CONTINENT_INFO.printMessage(Utils.convertMapToString(continentPath));
    MessageCli.FUEL_CONTINENT_INFO.printMessage(
        mostExpensiveContinent
            + " ("
            + Integer.toString(continentPath.get(mostExpensiveContinent))
            + ")");
  }

  /**
   * Given two countries as the start and end point, returns the shortest route between them using a
   * breadth-first-search.
   *
   * @param origin the country to start the search from.
   * @param destination the country to end the search at.
   * @return a list that details the journey from start to end.
   */
  private List<String> getShortestRoute(String origin, String destination) {
    Set<String> visited = new HashSet<>();
    Queue<String> queue = new LinkedList<>();
    Map<String, String> prev = new HashMap<>();

    queue.add(origin);
    visited.add(origin);

    while (!queue.isEmpty()) {
      String country = queue.poll();

      if (country.equals(destination)) {
        // reconstruct path
        List<String> path = new ArrayList<>();
        for (String at = destination; at != null; at = prev.get(at)) {
          path.addFirst(at);
        }
        return path; // mission success!
      }

      for (String neighbor : countryGraph.getNeighbors(country)) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
          prev.put(neighbor, country); // so we can track where we came from
        }
      }
    }
    // if no path is possible, in theory is impossible to reach here because in the data we've been
    // given each country has at least one neighbor
    return null;
  }
}
