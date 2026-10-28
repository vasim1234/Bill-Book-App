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
      version: 8, // Version 8
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, customerName TEXT, customerMobile TEXT, totalAmount REAL, date TEXT, paymentStatus TEXT)');
        await db.execute('CREATE TABLE bill_items(id INTEGER PRIMARY KEY AUTOINCREMENT, billId INTEGER, itemName TEXT, quantity INTEGER, price REAL)');
        await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemName TEXT, price REAL, purchasePrice REAL, stock INTEGER)');
        await db.execute('CREATE TABLE settings(id INTEGER PRIMARY KEY, businessName TEXT, ownerName TEXT, mobile TEXT, address TEXT, upiId TEXT, theme TEXT, gst TEXT, businessType TEXT)');
        await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT)');
        await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, customerId INTEGER, amount REAL, type TEXT, note TEXT, date TEXT)');
        await db.execute('CREATE TABLE staff(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT, dailyWage REAL)');
        await db.execute('CREATE TABLE attendance(id INTEGER PRIMARY KEY AUTOINCREMENT, staffId INTEGER, date TEXT, status TEXT, paymentStatus TEXT)');
        await db.execute('CREATE TABLE staff_payments(id INTEGER PRIMARY KEY AUTOINCREMENT, staffId INTEGER, amount REAL, note TEXT, date TEXT)');
        await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE, password TEXT)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT)');
          await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, customerId INTEGER, amount REAL, type TEXT, note TEXT, date TEXT)');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE settings ADD COLUMN theme TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE settings ADD COLUMN gst TEXT');
          await db.execute('ALTER TABLE settings ADD COLUMN businessType TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('CREATE TABLE staff(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, mobile TEXT, dailyWage REAL)');
          await db.execute('CREATE TABLE attendance(id INTEGER PRIMARY KEY AUTOINCREMENT, staffId INTEGER, date TEXT, status TEXT, paymentStatus TEXT)');
        }
        if (oldVersion < 6) {
          await db.execute('CREATE TABLE staff_payments(id INTEGER PRIMARY KEY AUTOINCREMENT, staffId INTEGER, amount REAL, note TEXT, date TEXT)');
        }
        if (oldVersion < 7) {
          await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE, password TEXT)');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE items ADD COLUMN purchasePrice REAL DEFAULT 0.0');
        }
      }
    );
  }

  // ================= USER AUTH FUNCTIONS =================

  Future<int> registerUser(String email, String password) async {
    Database db = await database;
    return await db.insert('users', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users', 
      where: 'email = ? AND password = ?', 
      whereArgs: [email, password]
    );
    if (result.isNotEmpty) return result.first;
    return null;
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
      if (t['type'] == 'DIYA') {
        totalLena += amount; 
      } else if (t['type'] == 'LIYA') {
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
      if (t['type'] == 'DIYA') balance += amount; 
      if (t['type'] == 'LIYA') balance -= amount; 
    }
    return balance;
  }

  Future<int> updateCustomer(int id, String name, String mobile) async {
    Database db = await database;
    return await db.update('customers', {'name': name, 'mobile': mobile}, where: 'id = ?', whereArgs: [id]);
  }

  // ================= STOCK & BILL FUNCTIONS =================

  Future<int> insertItem(Map<String, dynamic> row) async { Database db = await database; return await db.insert('items', row); }
  
  Future<List<Map<String, dynamic>>> getAllItems() async { Database db = await database; return await db.query('items', orderBy: 'id DESC'); }
  
  Future<int> updateItemStock(int id, int newStock) async { Database db = await database; return await db.update('items', {'stock': newStock}, where: 'id = ?', whereArgs: [id]); }
  
  Future<int> deleteItem(int id) async { Database db = await database; return await db.delete('items', where: 'id = ?', whereArgs: [id]); }

  Future<int> updateItem(int id, String name, double price, double purchasePrice, int stock) async {
    Database db = await database;
    return await db.update(
      'items', 
      {'itemName': name, 'price': price, 'purchasePrice': purchasePrice, 'stock': stock}, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

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
  
  // Theme update function (Fixed to handle missing settings row)
  Future<int> updateTheme(String newTheme) async {
    Database db = await database;
    List<Map<String, dynamic>> existing = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (existing.isEmpty) {
      return await db.insert('settings', {'id': 1, 'theme': newTheme});
    } else {
      return await db.update(
        'settings', 
        {'theme': newTheme}, 
        where: 'id = ?', 
        whereArgs: [1]
      );
    }
  }

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

  // ================= STAFF FUNCTIONS =================

  Future<int> insertStaff(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('staff', row);
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    Database db = await database;
    return await db.query('staff', orderBy: 'name ASC');
  }

  Future<int> insertAttendance(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('attendance', row);
  }

  Future<List<Map<String, dynamic>>> getTodayAttendance(String todayDate) async {
    Database db = await database;
    return await db.query('attendance', where: 'date = ?', whereArgs: [todayDate]);
  }

  // ================= STAFF PAYMENT FUNCTIONS =================

  Future<int> insertStaffPayment(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('staff_payments', row);
  }

  Future<List<Map<String, dynamic>>> getStaffPayments(int staffId) async {
    Database db = await database;
    return await db.query('staff_payments', where: 'staffId = ?', whereArgs: [staffId], orderBy: 'id DESC');
  }

  Future<int> deleteStaff(int staffId) async {
    Database db = await database;
    await db.delete('attendance', where: 'staffId = ?', whereArgs: [staffId]);
    await db.delete('staff_payments', where: 'staffId = ?', whereArgs: [staffId]);
    return await db.delete('staff', where: 'id = ?', whereArgs: [staffId]);
  }

  Future<Map<String, dynamic>> getStaffAttendanceSummary(int staffId) async {
    Database db = await database;
    
    List<Map<String, dynamic>> staffData = await db.query('staff', where: 'id = ?', whereArgs: [staffId]);
    double dailyWage = 0.0;
    if (staffData.isNotEmpty) {
      dailyWage = (staffData.first['dailyWage'] as num).toDouble();
    }

    List<Map<String, dynamic>> presentData = await db.query(
      'attendance', 
      where: 'staffId = ? AND status = ?', 
      whereArgs: [staffId, 'Present']
    );
    
    int presentDays = presentData.length;
    double totalEarned = presentDays * dailyWage;

    return {
      'presentDays': presentDays,
      'totalEarned': totalEarned,
    };
  }
}
  // ================= TRANSACTION EDIT & DELETE FUNCTIONS =================

  Future<int> updateTransaction(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update(
      'transactions', 
      row, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'transactions', 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }
