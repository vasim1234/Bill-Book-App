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
      version: 2, // Version badha diya (kyunki nayi table add ho rahi hai)
      onCreate: (db, version) async {
        // Purani Bills table
        await db.execute(
          'CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, customerName TEXT, itemName TEXT, quantity INTEGER, price REAL, totalAmount REAL, date TEXT)',
        );
        // Nayi Items (Stock) table
        await db.execute(
          'CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, stock INTEGER)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, stock INTEGER)',
          );
        }
      }
    );
  }

  // --- KHATA (Bills) Functions ---
  Future<int> insertBill(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('bills', row);
  }

  Future<List<Map<String, dynamic>>> getAllBills() async {
    Database db = await database;
    return await db.query('bills', orderBy: 'id DESC');
  }

  Future<int> deleteBill(int id) async {
    Database db = await database;
    return await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // --- STOCK (Items) Functions ---
  Future<int> insertItem(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('items', row);
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    Database db = await database;
    return await db.query('items', orderBy: 'id DESC');
  }
  
  Future<int> updateItemStock(int id, int newStock) async {
    Database db = await database;
    return await db.update('items', {'stock': newStock}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteItem(int id) async {
    Database db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
