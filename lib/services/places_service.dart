import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:postnow/environment/api_keys.dart';

class PlacesService {
  final _places = new GoogleMapsPlaces(apiKey: GOOGLE_API_KEY_PLACES_AND_DIRECTIONS);

  Location _myLoc;
  PlacesService(Position position) {
    _myLoc = Location(position.latitude, position.longitude);
  }

  Future<List<PlacesSearchResult>> getPlaces(String keyword) async {
    PlacesSearchResponse response = await _places.searchNearbyWithRadius(_myLoc, 10000, keyword: keyword);
    return response.results.where((e) => e?.openingHours?.openNow??false).toList(growable: false);
  }
}