import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

import 'job.dart';

class Address {
  LatLng coordinates;
  String country;
  String city;
  String area;
  String locality;
  String subLocality;
  String postalCode;
  String street;
  String houseNumber;
  String doorNumber;
  String doorName;

  Address({this.coordinates, this.country, this.city, this.area, this.locality, this.subLocality, this.postalCode, this.street, this.houseNumber, this.doorNumber, this.doorName});

  Address.fromAddressComponents(List<AddressComponent> formattedAddress, {this.coordinates, this.houseNumber, this.doorNumber}) {
    formattedAddress.forEach((value) {
      value.types.forEach((type) {
        switch (type) {
          case "floor":
            doorNumber = value.longName;
            break;
          case "street_number":
            if (houseNumber != null)
              break;
            houseNumber = value.longName;
            break;
          case "route":
            street = value.longName;
            break;
          case "locality":
            locality = value.longName;
            break;
          case "administrative_area_level_1":
            area = value.longName;
            break;
          case "administrative_area_level_2":
          // TODO understand what this is
            break;
          case "country":
            country = value.longName;
            break;
          case "postal_code":
            postalCode = value.longName;
            break;
        }
      });
    });
  }

  Address.fromSnapshot(DataSnapshot snapshot) {
    coordinates = Job.stringToLatLng(snapshot.value["coordinates"]);
    country = snapshot.value["country"];
    city = snapshot.value["city"];
    area = snapshot.value["area"];
    locality = snapshot.value["locality"];
    subLocality = snapshot.value["subLocality"];
    postalCode = snapshot.value["postalCode"];
    street = snapshot.value["street"];
    houseNumber = snapshot.value["house_number"];
    doorNumber = snapshot.value["door_number"];
    doorName = snapshot.value["door_name"];
  }

  Address.fromJson(Map json) {
    coordinates = Job.stringToLatLng(json["coordinates"]);
    country = json["country"];
    city = json["city"];
    area = json["area"];
    locality = json["locality"];
    subLocality = json["subLocality"];
    postalCode = json["postalCode"];
    street = json["street"];
    houseNumber = json["house_number"];
    doorNumber = json["door_number"];
    doorName = json["door_name"];
  }

  Map toMap() => {
    'coordinates': Job.latLngToString(coordinates),
    'country': country,
    'city': city,
    'area': area,
    'locality': locality,
    'subLocality': subLocality,
    'postalCode': postalCode,
    'street': street,
    'house_number': houseNumber,
    'door_number': doorNumber,
    'door_name': doorName,
  };

  Address.fromLatLng(LatLng latLng) {
    coordinates = latLng;
  }

  updateWithPlaceMark(Placemark placeMark) {
    country = placeMark.country;
    postalCode = placeMark.postalCode;
    city = placeMark.administrativeArea;
    area = placeMark.subAdministrativeArea;
    locality = placeMark.locality;
    subLocality = placeMark.subLocality;
    street = placeMark.thoroughfare;
    houseNumber = placeMark.subThoroughfare;
    if (coordinates == null)
      coordinates = LatLng(placeMark.position.latitude, placeMark.position.longitude);
  }

  String getAddress({bool withDoorNumber = true}) {
    StringBuffer address = StringBuffer();
    if (isStringNotEmpty(street))
      address.write(street);
    if (isStringNotEmpty(houseNumber))
      address.write(" " + houseNumber);
    if (isStringNotEmpty(doorNumber) && withDoorNumber) {
      address.write(isStringNotEmpty(houseNumber)?"/":" ?/");
      address.write(doorNumber);
    }
    if (isStringNotEmpty(area))
      address.write(" " + area);
    if (isStringNotEmpty(country)) {
      address.write(isStringNotEmpty(area)?"/":" ?/");
      address.write(country);
    }
    return address.toString();
  }

  static bool isStringNotEmpty(String val) {
    return val != null && val.length > 0;
  }

  bool hasDoorNumber() => isStringNotEmpty(doorNumber);

  bool alakadar(String searchText) {
    return searchText == null || searchText.isEmpty ||
        country?.toLowerCase()?.contains(searchText) ?? false ||
        city?.toLowerCase()?.contains(searchText) ?? false ||
        area?.toLowerCase()?.contains(searchText) ?? false ||
        locality?.toLowerCase()?.contains(searchText) ?? false ||
        subLocality?.toLowerCase()?.contains(searchText) ?? false ||
        postalCode?.toLowerCase()?.contains(searchText) ?? false ||
        street?.toLowerCase()?.contains(searchText) ?? false ||
        houseNumber?.toLowerCase()?.contains(searchText) ?? false ||
        doorNumber?.toLowerCase()?.contains(searchText) ?? false;
  }

  @override
  bool operator == (covariant Address other) => coordinates == other.coordinates;

  @override
  int get hashCode => super.hashCode;
}