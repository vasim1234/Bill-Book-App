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
    String path = join(await getDatabasesPath(), 'bill_book_v2.db'); // Naya Database Name
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. BILLS Table (Main Bill ki detail)
        await db.execute('''
          CREATE TABLE bills(
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            customerName TEXT, 
            customerMobile TEXT, 
            totalAmount REAL, 
            date TEXT,
            paymentStatus TEXT
          )
        ''');

        // 2. BILL ITEMS Table (Bill ke andar kya kya hai)
        await db.execute('''
          CREATE TABLE bill_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            billId INTEGER,
            itemName TEXT,
            quantity INTEGER,
            price REAL
          )
        ''');

        // 3. ITEMS (Stock) Table
        await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, stock INTEGER)');
        
        // 4. SETTINGS Table
        await db.execute('CREATE TABLE settings(id INTEGER PRIMARY KEY, businessName TEXT, ownerName TEXT, mobile TEXT, address TEXT, upiId TEXT)');
      },
    );
  }

  // --- STOCK ---
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

  // --- SETTINGS ---
  Future<Map<String, dynamic>?> getSettings() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> saveSettings(Map<String, dynamic> row) async {
    Database db = await database;
    row['id'] = 1;
    return await db.insert('settings', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- NAYA: MULTI-ITEM BILL SAVE KARNA ---
  Future<void> saveFullBill(Map<String, dynamic> billData, List<Map<String, dynamic>> billItems) async {
    Database db = await database;
    
    // 1. Bill ko save karo
    int billId = await db.insert('bills', billData);

    // 2. Bill ke saare items save karo aur Stock kam karo
    for (var item in billItems) {
      item['billId'] = billId; // Bill ID daalo
      await db.insert('bill_items', item);

      // Stock update karo
      List<Map<String, dynamic>> stockData = await db.query('items', where: 'itemName = ?', whereArgs: [item['itemName']]);
      if (stockData.isNotEmpty) {
        int currentStock = stockData.first['stock'];
        int newStock = currentStock - (item['quantity'] as int);
        if (newStock < 0) newStock = 0;
        await db.update('items', {'stock': newStock}, where: 'id = ?', whereArgs: [stockData.first['id']]);
      }
    }
  }

  // --- KHATA (Bill History) ---
  Future<List<Map<String, dynamic>>> getAllBills() async {
    Database db = await database;
    return await db.query('bills', orderBy: 'id DESC');
  }
}
