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
      version: 3, // Version badha diya
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, customerName TEXT, itemName TEXT, quantity INTEGER, price REAL, totalAmount REAL, date TEXT)');
        await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, stock INTEGER)');
        // Nayi Settings table
        await db.execute('CREATE TABLE settings(id INTEGER PRIMARY KEY, businessName TEXT, ownerName TEXT, mobile TEXT, address TEXT, upiId TEXT)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, stock INTEGER)');
        }
        if (oldVersion < 3) {
          await db.execute('CREATE TABLE settings(id INTEGER PRIMARY KEY, businessName TEXT, ownerName TEXT, mobile TEXT, address TEXT, upiId TEXT)');
        }
      }
    );
  }

  // --- KHATA & STOCK FUNCTIONS (Purane wale) ---
  Future<int> insertBill(Map<String, dynamic> row) async {
    Database db = await database;
    int itemId = row['itemId'];
    int qty = row['quantity'];
    List<Map<String, dynamic>> itemData = await db.query('items', where: 'id = ?', whereArgs: [itemId]);
    if (itemData.isNotEmpty) {
      int currentStock = itemData.first['stock'];
      int newStock = currentStock - qty;
      if (newStock < 0) newStock = 0;
      await db.update('items', {'stock': newStock}, where: 'id = ?', whereArgs: [itemId]);
    }
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

  // --- SETTINGS FUNCTIONS ---
  Future<Map<String, dynamic>?> getSettings() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) return result.first;
    return null; // Agar pehli baar app khuli hai toh null aayega
  }

  Future<int> saveSettings(Map<String, dynamic> row) async {
    Database db = await database;
    row['id'] = 1; // Hum hamesha ek hi row update karenge
    return await db.insert('settings', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
