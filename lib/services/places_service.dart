import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:postnow/environment/api_keys.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/services/remote_config_service.dart';

class PlacesService {
  final _places = new GoogleMapsPlaces(apiKey: GOOGLE_API_KEY_PLACES_AND_DIRECTIONS);

  Location _myLoc;
  PlacesService(Position position) {
    _myLoc = Location(position.latitude, position.longitude);
  }

  Future<List<PlacesSearchResult>> getPlaces(String keyword) async {
    PlacesSearchResponse response = await _places.searchNearbyWithRadius(_myLoc, 2500, keyword: keyword);
    List<String> blackList =  RemoteConfigService.getStringList(FIREBASE_REMOTE_CONFIG_MARKET_TOPICS_BLACK_LIST);
    print(blackList);
    return response.results.where((element) => !blackList.contains(element.placeId)).toList();
  }
}