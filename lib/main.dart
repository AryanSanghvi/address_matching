import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

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
              Text(
                "Latitude: $latitude",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "Longitude: $longitude",
                style: TextStyle(fontSize: 16),
              ),
              if (similarityPercentage != null)
                Text(
                  "Similarity Percentage: ${(similarityPercentage! * 100).toStringAsFixed(2)}%",
                  style: TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void convertAddressToLatLng() async {
    String address = "$doorNumber, $building, $street, $area, $city, $country, $pinCode";
    List<Location> locations = await locationFromAddress(address);

    if (locations.isNotEmpty) {
      setState(() {
        latitude = locations[0].latitude;
        longitude = locations[0].longitude;
      });

      double? percentage = await calculateSimilarity();
      setState(() {
        similarityPercentage = percentage;
      });

      // Insert address into the database
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

    int totalFields = 7; // Total number of address fields

    // Initialize total similarity count
    int totalSimilarityCount = 0;
    int similarityCount = 0;
    // Calculate similarity counts for each field
    for (Address savedAddress in savedAddresses) {
   //   int similarityCount = 0;
      if (savedAddress.doorNumber == doorNumber) {
        similarityCount++;
      }
      if (savedAddress.building == building) {
        similarityCount++;
      }
      if (savedAddress.street == street) {
        similarityCount++;
      }
      if (savedAddress.area == area) {
        similarityCount++;
      }
      if (savedAddress.city == city) {
        similarityCount++;
      }
      if (savedAddress.country == country) {
        similarityCount++;
      }
      if (savedAddress.pinCode == pinCode) {
        similarityCount++;
      }

      // Update total similarity count
     // totalSimilarityCount += similarityCount;
    }

    // Calculate total similarity percentage
    double totalSimilarityPercentage = similarityCount / ( totalFields);

    return totalSimilarityPercentage * 100;
  }
}
