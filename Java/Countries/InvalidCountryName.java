package nz.ac.auckland.se281;


public class InvalidCountryName extends Exception {

  private final String invalidCountry;

  public InvalidCountryName(String invalidCountry) {
    super(MessageCli.INVALID_COUNTRY.getMessage(invalidCountry));
    this.invalidCountry = invalidCountry;
  }

  public String getInvalidCountry() {
    return this.invalidCountry;
  }
}
