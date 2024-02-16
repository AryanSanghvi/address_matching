import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database/dbhelper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String doorNumber = "";
  String building = "";
  String street = "";
  String area = "";
  String city = "";
  String country = "";
  String pinCode = "";
  double latitude = 0.0;
  double longitude = 0.0;
  double? similarityPercentage;
  int? adjustedAddressId1;
  int? adjustedAddressId2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Address to Lat/Lng Converter"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter the address details:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  doorNumber = value;
                },
                decoration: InputDecoration(labelText: "Door Number"),
              ),
              TextField(
                onChanged: (value) {
                  building = value;
                },
                decoration: InputDecoration(labelText: "Building"),
              ),
              TextField(
                onChanged: (value) {
                  street = value;
                },
                decoration: InputDecoration(labelText: "Street"),
              ),
              TextField(
                onChanged: (value) {
                  area = value;
                },
                decoration: InputDecoration(labelText: "Area"),
              ),
              TextField(
                onChanged: (value) {
                  city = value;
                },
                decoration: InputDecoration(labelText: "City"),
              ),
              TextField(
                onChanged: (value) {
                  country = value;
                },
                decoration: InputDecoration(labelText: "Country"),
              ),
              TextField(
                onChanged: (value) {
                  pinCode = value;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Pin Code"),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  convertAddressToLatLng();
                },
                child: Text("Convert"),
              ),
              SizedBox(height: 16),
              if (adjustedAddressId1 != null && adjustedAddressId2 != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Adjusted Latitude: ${latitude.toString()} (${adjustedAddressId1.toString()} and ${adjustedAddressId2.toString()})",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Longitude: ${longitude.toString()}",
                      style: TextStyle(fontSize: 16),
                    ),
                    if (similarityPercentage != null)
                      Text(
                        "Adjusted Similarity Percentage: ${(similarityPercentage! * 100).toStringAsFixed(2)}%",
                        style: TextStyle(fontSize: 16),
                      ),
                    Text(
                      "IDs: ${adjustedAddressId1.toString()} and ${adjustedAddressId2.toString()}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              if (adjustedAddressId1 == null || adjustedAddressId2 == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Latitude: ${latitude.toString()}",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Longitude: ${longitude.toString()}",
                      style: TextStyle(fontSize: 16),
                    ),
                    if (similarityPercentage != null)
                      Text(
                        "Similarity Percentage: ${(similarityPercentage! * 100).toStringAsFixed(2)}%",
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  navigateToLocation(latitude, longitude);
                },
                child: Text("Navigate"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void convertAddressToLatLng() async {
    String address =
        "$doorNumber, $building, $street, $area, $city, $country, $pinCode";
    address = address.toLowerCase();
    List<Location> locations = await locationFromAddress(address);
    doorNumber = doorNumber.toLowerCase();
    building = building.toLowerCase();
    street = street.toLowerCase();
    area = area.toLowerCase();
    city = city.toLowerCase();
    country = country.toLowerCase();
    pinCode = pinCode.toLowerCase();
    if (locations.isNotEmpty) {
      setState(() {
        latitude = locations[0].latitude;
        longitude = locations[0].longitude;
      });
      double? percentage = await calculateSimilarity();
      setState(() {
        similarityPercentage = percentage;
      });

      if (similarityPercentage != null && similarityPercentage == 1.0) {
        print(
            "Address already exists with 100% similarity. Not saving to database.");
        return;
      }

      if (similarityPercentage != null &&
          similarityPercentage! >= 0.71 &&
          similarityPercentage != 1.0) {
        List<Address> savedAddresses = await DatabaseHelper.getAddresses();
        List<Address> similarAddresses = savedAddresses
            .where((address) => calculateSimilarityCount(address) >= 5)
            .toList();

        if (similarAddresses.length >= 2) {
          similarAddresses.sort((a, b) =>
              calculateSimilarityCount(b).compareTo(calculateSimilarityCount(a)));

          Address firstSimilarAddress = similarAddresses[0];
          Address secondSimilarAddress = similarAddresses[1];

          double avgLatitude =
              (firstSimilarAddress.latitude + secondSimilarAddress.latitude) / 2;
          double avgLongitude = (firstSimilarAddress.longitude +
              secondSimilarAddress.longitude) /
              2;

          setState(() {
            latitude = avgLatitude;
            longitude = avgLongitude;
            adjustedAddressId1 = firstSimilarAddress.id;
            adjustedAddressId2 = secondSimilarAddress.id;
          });
          print(
              "Coordinates adjusted using addresses with IDs: ${firstSimilarAddress.id} and ${secondSimilarAddress.id}");
        }
      } else {
        setState(() {
          adjustedAddressId1 = null;
          adjustedAddressId2 = null;
        });
      }

      if (similarityPercentage == null || similarityPercentage! < 0.71) {
        latitude = locations[0].latitude;
        longitude = locations[0].longitude;
      }

      await DatabaseHelper.insertAddress(Address(
        doorNumber: doorNumber,
        building: building,
        street: street,
        area: area,
        city: city,
        country: country,
        pinCode: pinCode,
        latitude: latitude,
        longitude: longitude,
      ));

      if (similarityPercentage != null && similarityPercentage! >= 0.71) {
        print("Coordinates adjusted based on similar addresses.");
      }
    } else {
      setState(() {
        latitude = 0.0;
        longitude = 0.0;
      });
    }
  }

  Future<double?> calculateSimilarity() async {
    List<Address> savedAddresses = await DatabaseHelper.getAddresses();

    if (savedAddresses.isEmpty) {
      return null;
    }

    int totalFields = 7;
    int similarityCount = 0;

    for (Address savedAddress in savedAddresses) {
      int currentSimilarityCount = calculateSimilarityCount(savedAddress);
      if (currentSimilarityCount == totalFields) {
        return 1.0;
      } else if (currentSimilarityCount > similarityCount) {
        similarityCount = currentSimilarityCount;
      }
    }

    double similarityPercentage = similarityCount / totalFields;
    return similarityPercentage;
  }

  int calculateSimilarityCount(Address savedAddress) {
    int similarityCount = 0;
    int flag = 0;
    if (savedAddress.pinCode == pinCode && flag == 0) {
      similarityCount++;
    } else {
      flag = 1;
    }
    if (savedAddress.country == country && flag == 0) {
      similarityCount++;
    } else {
      flag = 1;
    }
    if (savedAddress.city == city && flag == 0) {
      similarityCount++;
    } else {
      flag = 1;
    }
    if (savedAddress.area == area && flag == 0) {
      similarityCount++;
    } else {
      flag = 1;
    }
    if (savedAddress.street == street && flag == 0) similarityCount++;
    else {
      flag = 1;
    }
    if (savedAddress.building == building && flag == 0) {
      similarityCount++;
    } else {
      flag = 1;
    }
    if (savedAddress.doorNumber == doorNumber && flag == 0) {
      similarityCount++;
    } else {
      flag = 1;
    }
    return similarityCount;
  }

  void navigateToLocation(double latitude, double longitude) async {
    String url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }
}
