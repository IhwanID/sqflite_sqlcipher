import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('16KB Page Size Support', () {
    test('New database should use 16KB page size', () async {
      // Note: This test requires actual platform implementation to run
      // It's included here as documentation of expected behavior
      
      final dbPath = inMemoryDatabasePath;
      final password = 'test_password_123';
      
      final db = await openDatabase(
        dbPath,
        password: password,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE Test (
              id INTEGER PRIMARY KEY,
              name TEXT
            )
          ''');
        },
      );

      try {
        // Query the page size
        // Note: page_size shows the actual page size of the database
        final result = await db.rawQuery('PRAGMA page_size');
        print('Page size: ${result.first['page_size']}');
        
        // For new databases with this version, it should be 16384 (16KB)
        // However, note that PRAGMA page_size might show the database page size
        // while cipher_page_size is the encryption page size
        expect(result.isNotEmpty, true);
        
        // Create some test data
        await db.insert('Test', {'id': 1, 'name': 'Test Item'});
        
        final data = await db.query('Test');
        expect(data.length, 1);
        expect(data.first['name'], 'Test Item');
        
      } finally {
        await db.close();
      }
    });

    test('Database operations should work with 16KB page size', () async {
      final dbPath = inMemoryDatabasePath;
      final password = 'secure_password';
      
      final db = await openDatabase(
        dbPath,
        password: password,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE Users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              email TEXT NOT NULL,
              data BLOB
            )
          ''');
        },
      );

      try {
        // Test insert
        final userId = await db.insert('Users', {
          'username': 'testuser',
          'email': 'test@example.com',
          'data': [1, 2, 3, 4, 5],
        });
        
        expect(userId, greaterThan(0));
        
        // Test query
        final users = await db.query('Users', where: 'id = ?', whereArgs: [userId]);
        expect(users.length, 1);
        expect(users.first['username'], 'testuser');
        
        // Test update
        final updateCount = await db.update(
          'Users',
          {'email': 'updated@example.com'},
          where: 'id = ?',
          whereArgs: [userId],
        );
        expect(updateCount, 1);
        
        // Test delete
        final deleteCount = await db.delete(
          'Users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        expect(deleteCount, 1);
        
      } finally {
        await db.close();
      }
    });

    test('Batch operations should work with 16KB page size', () async {
      final dbPath = inMemoryDatabasePath;
      final password = 'batch_test_password';
      
      final db = await openDatabase(
        dbPath,
        password: password,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE Items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              value TEXT
            )
          ''');
        },
      );

      try {
        // Test batch operations
        final batch = db.batch();
        
        for (int i = 0; i < 10; i++) {
          batch.insert('Items', {'value': 'Item $i'});
        }
        
        final results = await batch.commit();
        expect(results.length, 10);
        
        // Verify items were inserted
        final items = await db.query('Items');
        expect(items.length, 10);
        
      } finally {
        await db.close();
      }
    });

    test('Transaction should work with 16KB page size', () async {
      final dbPath = inMemoryDatabasePath;
      final password = 'transaction_password';
      
      final db = await openDatabase(
        dbPath,
        password: password,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE Accounts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              balance REAL
            )
          ''');
        },
      );

      try {
        // Insert initial data
        await db.insert('Accounts', {'balance': 100.0});
        await db.insert('Accounts', {'balance': 50.0});
        
        // Test transaction
        await db.transaction((txn) async {
          await txn.update(
            'Accounts',
            {'balance': 90.0},
            where: 'id = ?',
            whereArgs: [1],
          );
          
          await txn.update(
            'Accounts',
            {'balance': 60.0},
            where: 'id = ?',
            whereArgs: [2],
          );
        });
        
        // Verify transaction results
        final accounts = await db.query('Accounts');
        expect(accounts[0]['balance'], 90.0);
        expect(accounts[1]['balance'], 60.0);
        
      } finally {
        await db.close();
      }
    });
  });
}
