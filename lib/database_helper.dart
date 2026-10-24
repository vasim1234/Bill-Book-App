import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bill_book.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, customerName TEXT, itemName TEXT, quantity INTEGER, price REAL, totalAmount REAL, date TEXT)',
        );
      },
    );
  }

  // Data Save karne ke liye
  Future<int> insertBill(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('bills', row);
  }

  // Data padhne ke liye
  Future<List<Map<String, dynamic>>> getAllBills() async {
    Database db = await instance.database;
    return await db.query('bills', orderBy: 'id DESC');
  }
}
