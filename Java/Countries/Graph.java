package nz.ac.auckland.se281;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class Graph {

  private Map<String, CountryNode> countryInfo;
  private Map<String, ArrayList<String>> adjacencyList;

  public Graph() {
    this.countryInfo = new HashMap<>();
    this.adjacencyList = new HashMap<>();
  }

  /** Add a new node to the graph. */
  public void addCountry(String name, String continent, int fuelCost) {
    countryInfo.put(name, new CountryNode(name, continent, fuelCost));
    adjacencyList.putIfAbsent(name, new ArrayList<>());
  }

  /** Add a new connection between nodes. */
  public void addEdge(String from, String to) {
    adjacencyList.get(from).add(to);
  }

  public String getContinent(String country) {
    return countryInfo.get(country).getContinent();
  }

  public int getFuelCost(String country) {
    return countryInfo.get(country).getFuelCost();
  }

  public ArrayList<String> getNeighbors(String country) {
    return adjacencyList.get(country);
  }

  public boolean containsCountry(String country) {
    return countryInfo.containsKey(country);
  }
}
