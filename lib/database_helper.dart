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
    version: 3, // Version 3 kar diya (theme column ke liye)
    onCreate: (db, version) async {
      await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, customerName TEXT, customerMobile TEXT, totalAmount REAL, date TEXT, paymentStatus TEXT)');
      await db.execute('CREATE TABLE bill_items(id INTEGER PRIMARY KEY AUTOINCREMENT, billId INTEGER, itemName TEXT, quantity INTEGER, price REAL)');
      await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, stock INTEGER)');
      // Settings table mein 'theme' column add kiya
      await db.execute('CREATE TABLE settings(id INTEGER PRIMARY KEY, businessName TEXT, ownerName TEXT, mobile TEXT, address TEXT, upiId TEXT, theme TEXT)');
      
      await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT)');
      await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, customerId INTEGER, amount REAL, type TEXT, note TEXT, date TEXT)');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT)');
        await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, customerId INTEGER, amount REAL, type TEXT, note TEXT, date TEXT)');
      }
      if (oldVersion < 3) {
        // Purani settings table mein 'theme' column add kar rahe hain
        await db.execute('ALTER TABLE settings ADD COLUMN theme TEXT');
      }
    }
  );
  }

  // ================= CASH / KHATA FUNCTIONS =================

  Future<int> insertCustomer(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('customers', row);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    Database db = await database;
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> getCustomerTransactions(int customerId) async {
    Database db = await database;
    return await db.query('transactions', where: 'customerId = ?', whereArgs: [customerId], orderBy: 'id DESC');
  }

  Future<Map<String, double>> getTotalCashSummary() async {
    Database db = await database;
    List<Map<String, dynamic>> transactions = await db.query('transactions');
    
    double totalLena = 0.0; 
    double totalDena = 0.0; 

    for (var t in transactions) {
      double amount = (t['amount'] as num).toDouble();
      if (t['type'] == 'LIYA') {
        totalLena += amount; 
      } else if (t['type'] == 'DIYA') {
        totalDena += amount; 
      }
    }
    return {'lena': totalLena, 'dena': totalDena};
  }

  Future<double> getCustomerBalance(int customerId) async {
    Database db = await database;
    List<Map<String, dynamic>> transactions = await db.query('transactions', where: 'customerId = ?', whereArgs: [customerId]);
    
    double balance = 0.0;
    for (var t in transactions) {
      double amount = (t['amount'] as num).toDouble();
      if (t['type'] == 'LIYA') balance += amount; 
      if (t['type'] == 'DIYA') balance -= amount; 
    }
    return balance;
  }

  // ================= STOCK & BILL FUNCTIONS =================

  Future<int> insertItem(Map<String, dynamic> row) async { Database db = await database; return await db.insert('items', row); }
  
  Future<List<Map<String, dynamic>>> getAllItems() async { Database db = await database; return await db.query('items', orderBy: 'id DESC'); }
  
  Future<int> updateItemStock(int id, int newStock) async { Database db = await database; return await db.update('items', {'stock': newStock}, where: 'id = ?', whereArgs: [id]); }
  
  Future<int> deleteItem(int id) async { Database db = await database; return await db.delete('items', where: 'id = ?', whereArgs: [id]); }

  // --- YAHAN WO DO MISSING FUNCTIONS ADD KIYE HAIN ---
  
  // 1. Item ko Edit karne ke liye
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
    String currentMonth = DateTime.now().toString().substring(0, 7); 
    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(totalAmount) as total FROM bills WHERE date LIKE ?", 
      ['$currentMonth%']
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // ---------------------------------------------------

  Future<Map<String, dynamic>?> getSettings() async { Database db = await database; List<Map<String, dynamic>> result = await db.query('settings', where: 'id = ?', whereArgs: [1]); if (result.isNotEmpty) return result.first; return null; }
  
  Future<int> saveSettings(Map<String, dynamic> row) async { Database db = await database; row['id'] = 1; return await db.insert('settings', row, conflictAlgorithm: ConflictAlgorithm.replace); }
  
  Future<int> saveFullBill(Map<String, dynamic> billData, List<Map<String, dynamic>> billItems) async {
    Database db = await database;
    int billId = await db.insert('bills', billData);
    for (var item in billItems) {
      item['billId'] = billId;
      await db.insert('bill_items', item);
      List<Map<String, dynamic>> stockData = await db.query('items', where: 'itemName = ?', whereArgs: [item['itemName']]);
      if (stockData.isNotEmpty) {
        int currentStock = stockData.first['stock'];
        int newStock = currentStock - (item['quantity'] as int);
        if (newStock < 0) newStock = 0;
        await db.update('items', {'stock': newStock}, where: 'id = ?', whereArgs: [stockData.first['id']]);
      }
    }
    return billId;
  }
  
  Future<List<Map<String, dynamic>>> getAllBills() async { Database db = await database; return await db.query('bills', orderBy: 'id DESC'); }
  
  Future<int> deleteBill(int id) async { Database db = await database; await db.delete('bill_items', where: 'billId = ?', whereArgs: [id]); return await db.delete('bills', where: 'id = ?', whereArgs: [id]); }
  
  Future<List<Map<String, dynamic>>> getBillItems(int billId) async { Database db = await database; return await db.query('bill_items', where: 'billId = ?', whereArgs: [billId]); }
// Customer ki detail update karne ke liye
Future<int> updateCustomer(int id, String name, String mobile) async {
  Database db = await database;
  return await db.update('customers', {'name': name, 'mobile': mobile}, where: 'id = ?', whereArgs: [id]);
}
}

