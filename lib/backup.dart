import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Get the device's documents directory to store the database
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'address_database.db');

    // Open/create the database at a given path
    return openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  static Future<void> _createDatabase(Database db, int version) async {
    // Create the addresses table with separate columns for each address component
    await db.execute('''
      CREATE TABLE addresses(
        id INTEGER PRIMARY KEY,
        doorNumber TEXT NOT NULL,
        building TEXT NOT NULL,
        street TEXT NOT NULL,
        area TEXT NOT NULL,
        city TEXT NOT NULL,
        country TEXT NOT NULL,
        pinCode TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  // Insert an address into the database
  static Future<void> insertAddress(Address address) async {
    final Database db = await database;
    await db.insert(
      'addresses',
      address.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve all addresses from the database
  static Future<List<Address>> getAddresses() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('addresses');
    return List.generate(maps.length, (i) {
      return Address(
        id: maps[i]['id'],
        doorNumber: maps[i]['doorNumber'],
        building: maps[i]['building'],
        street: maps[i]['street'],
        area: maps[i]['area'],
        city: maps[i]['city'],
        country: maps[i]['country'],
        pinCode: maps[i]['pinCode'],
        latitude: maps[i]['latitude'],
        longitude: maps[i]['longitude'],
      );
    });
  }
}

class Address {
  final int? id;
  final String doorNumber;
  final String building;
  final String street;
  final String area;
  final String city;
  final String country;
  final String pinCode;
  final double latitude;
  final double longitude;

  Address({
    this.id,
    required this.doorNumber,
    required this.building,
    required this.street,
    required this.area,
    required this.city,
    required this.country,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doorNumber': doorNumber,
      'building': building,
      'street': street,
      'area': area,
      'city': city,
      'country': country,
      'pinCode': pinCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}