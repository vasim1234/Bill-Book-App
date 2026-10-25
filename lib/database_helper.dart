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
    String path = join(await getDatabasesPath(), 'bill_book_v2.db'); 
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
        await db.execute('''
          CREATE TABLE bill_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            billId INTEGER,
            itemName TEXT,
            quantity INTEGER,
            price REAL
          )
        ''');
        await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, stock INTEGER)');
        await db.execute('CREATE TABLE settings(id INTEGER PRIMARY KEY, businessName TEXT, ownerName TEXT, mobile TEXT, address TEXT, upiId TEXT)');
      },
    );
  }

  // --- STOCK FUNCTIONS ---
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
    return null;
  }

  Future<int> saveSettings(Map<String, dynamic> row) async {
    Database db = await database;
    row['id'] = 1;
    return await db.insert('settings', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- MULTI-ITEM BILL FUNCTIONS ---
  // Yahan Future<int> kiya hai taaki Bill ID wapas mile
  Future<int> saveFullBill(Map<String, dynamic> billData, List<Map<String, dynamic>> billItems) async {
    Database db = await database;
    
    // 1. Bill ko save karo
    int billId = await db.insert('bills', billData);

    // 2. Bill ke saare items save karo aur Stock kam karo
    for (var item in billItems) {
      item['billId'] = billId;
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
    
    // Bill ID return karo
    return billId;
  }

  // --- KHATA (Bill History) ---
  Future<List<Map<String, dynamic>>> getAllBills() async {
    Database db = await database;
    return await db.query('bills', orderBy: 'id DESC');
  }

  Future<int> deleteBill(int id) async {
    Database db = await database;
    await db.delete('bill_items', where: 'billId = ?', whereArgs: [id]);
    return await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // Bill ke items nikalne ke liye (Preview screen ke liye)
  Future<List<Map<String, dynamic>>> getBillItems(int billId) async {
    Database db = await database;
    return await db.query('bill_items', where: 'billId = ?', whereArgs: [billId]);
  }
  // 1. Item ko Edit/Update karne ke liye
Future<int> updateItem(int id, String name, double price, int stock) async {
  Database db = await database;
  return await db.update(
    'items', 
    {'itemName': name, 'price': price, 'stock': stock}, 
    where: 'id = ?', 
    whereArgs: [id]
  );
}

// 2. Is mahine ki Total Sale nikalne ke liye
Future<double> getThisMonthSale() async {
  Database db = await database;
  String currentMonth = DateTime.now().toString().substring(0, 7); // YYYY-MM format
  // Query: Sum of totalAmount where date starts with current month
  List<Map<String, dynamic>> result = await db.rawQuery(
    "SELECT SUM(totalAmount) as total FROM bills WHERE date LIKE ?", 
    ['$currentMonth%']
  );
  if (result.isNotEmpty && result.first['total'] != null) {
    return (result.first['total'] as num).toDouble();
  }
  return 0.0;
}
}
