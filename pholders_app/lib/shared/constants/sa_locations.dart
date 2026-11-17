/// South African provinces and the cities/towns offered for each.
///
/// Used by the registration forms so practice location is chosen from a fixed
/// list rather than typed freehand. Every entry here was checked against the
/// Open-Meteo geocoding API, which is what the backend uses to resolve a
/// practice location — see `GeocodingService.geocodeAddress`. Adding a name it
/// cannot resolve will make doctor signup fail with a 400.
class SaLocations {
  SaLocations._();

  /// The nine provinces, in the order they are shown.
  static const List<String> provinces = [
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'North West',
    'Northern Cape',
    'Western Cape',
  ];

  /// Cities and larger towns, keyed by province.
  static const Map<String, List<String>> citiesByProvince = {
    'Eastern Cape': [
      'East London',
      'Gqeberha',
      // The geocoder the backend uses returns nothing for 'Graaff-Reinet'
      // (the hyphen), and resolves 'Makhanda' to a town in Kazakhstan, so
      // these are the spellings that reach the right South African place.
      'Graaff Reinet',
      'Grahamstown',
      'Mthatha',
      'Qonce',
      'Queenstown',
      'Uitenhage',
    ],
    'Free State': [
      'Bethlehem',
      'Bloemfontein',
      'Kroonstad',
      'Parys',
      'Phuthaditjhaba',
      'Sasolburg',
      'Welkom',
    ],
    'Gauteng': [
      'Alberton',
      'Benoni',
      'Boksburg',
      'Centurion',
      'Germiston',
      'Johannesburg',
      'Kempton Park',
      'Krugersdorp',
      'Midrand',
      'Pretoria',
      'Randburg',
      'Roodepoort',
      'Sandton',
      'Soweto',
      'Springs',
      'Vanderbijlpark',
      'Vereeniging',
    ],
    'KwaZulu-Natal': [
      'Durban',
      'Empangeni',
      'Ladysmith',
      'Margate',
      'Newcastle',
      'Pietermaritzburg',
      'Pinetown',
      'Richards Bay',
      'Umhlanga',
    ],
    'Limpopo': [
      'Bela-Bela',
      'Lephalale',
      'Mokopane',
      'Musina',
      'Polokwane',
      'Thohoyandou',
      'Tzaneen',
    ],
    'Mpumalanga': [
      'Barberton',
      'Emalahleni',
      'Mbombela',
      'Middelburg',
      'Secunda',
      'Standerton',
      'White River',
    ],
    'North West': [
      'Brits',
      'Klerksdorp',
      'Lichtenburg',
      'Mahikeng',
      'Potchefstroom',
      'Rustenburg',
      'Vryburg',
    ],
    'Northern Cape': [
      'De Aar',
      'Kimberley',
      'Kuruman',
      'Springbok',
      'Upington',
    ],
    'Western Cape': [
      'Bellville',
      'Cape Town',
      'George',
      'Hermanus',
      'Knysna',
      'Mossel Bay',
      'Oudtshoorn',
      'Paarl',
      'Somerset West',
      'Stellenbosch',
      'Worcester',
    ],
  };

  /// Cities for [province], or an empty list when none is selected yet.
  static List<String> citiesFor(String province) =>
      citiesByProvince[province] ?? const [];
}
