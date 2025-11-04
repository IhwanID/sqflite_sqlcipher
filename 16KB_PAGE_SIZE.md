# 16 KB Page Size Support

## Overview

This fork of sqflite_sqlcipher now supports 16 KB page size for SQLCipher databases. The page size is automatically set to 16384 bytes (16 KB) when opening a database.

## Why 16 KB Page Size?

Using a 16 KB page size provides several benefits:

1. **Better Performance**: Larger page sizes can improve I/O efficiency by reducing the number of disk operations required for queries.
2. **Modern Storage Compatibility**: Many modern storage systems (especially SSDs and flash-based storage) work more efficiently with larger page sizes that match their internal block sizes.
3. **iOS/macOS Compatibility**: Apple's file systems (APFS) use 4 KB blocks by default, and 16 KB pages align well with these systems.

## Implementation Details

### Android

The page size is set in the `Database.java` file using SQLCipher's `SQLiteDatabaseHook`:

```java
SQLiteDatabaseHook pageSizeHook = new SQLiteDatabaseHook() {
    @Override
    public void preKey(SQLiteConnection database) {
        // Set page size to 16KB before key is set
        database.executeForLong("PRAGMA cipher_page_size = 16384;", null, null);
    }

    @Override
    public void postKey(SQLiteConnection database) {
        // Nothing to do after key is set
    }
};
```

The `PRAGMA cipher_page_size` must be set **before** the encryption key is applied.

### iOS/macOS

On iOS and macOS platforms, the page size is set in the `SqfliteSqlCipherPlugin.m` file:

```objectivec
[queue inDatabase:^(FMDatabase *database) {
    // Set page size to 16KB before setting the key
    [database executeUpdate:@"PRAGMA cipher_page_size = 16384"];
    
    if (password == nil) {
        [database setKey:@""];
    } else {
        [database setKey:password];
    }
    
    // ...
}];
```

## Compatibility

### New Databases

All new databases created with this version will automatically use a 16 KB page size.

### Existing Databases

**Important:** Existing databases created with a different page size (typically 4 KB) will continue to use their original page size. SQLCipher does not support changing the page size of an existing database.

If you need to migrate an existing database to use 16 KB pages, you will need to:

1. Create a new database with the desired page size
2. Copy all data from the old database to the new one
3. Replace the old database file with the new one

### Migration Example

```dart
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';

Future<void> migrateDatabase(String oldDbPath, String password) async {
  // Open the old database
  final oldDb = await openDatabase(
    oldDbPath,
    password: password,
  );

  // Create a new database with 16KB page size (automatic in this version)
  final newDbPath = join(dirname(oldDbPath), 'temp_new.db');
  final newDb = await openDatabase(
    newDbPath,
    password: password,
    version: await oldDb.getVersion(),
  );

  // Get all tables
  final tables = await oldDb.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
  );

  // Copy schema and data for each table
  for (final table in tables) {
    final tableName = table['name'] as String;
    
    // Get table schema
    final schema = await oldDb.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    
    // Create table in new database
    if (schema.isNotEmpty && schema.first['sql'] != null) {
      await newDb.execute(schema.first['sql'] as String);
      
      // Copy data
      final data = await oldDb.query(tableName);
      for (final row in data) {
        await newDb.insert(tableName, row);
      }
    }
  }

  await oldDb.close();
  await newDb.close();

  // Replace old database with new one
  final file = File(oldDbPath);
  final tempFile = File(newDbPath);
  await file.delete();
  await tempFile.rename(oldDbPath);
}
```

## Verification

You can verify the page size of your database by running:

```dart
final result = await db.rawQuery('PRAGMA page_size');
print('Page size: ${result.first['page_size']}');
```

For encrypted databases, you can check the cipher page size:

```dart
final result = await db.rawQuery('PRAGMA cipher_page_size');
print('Cipher page size: ${result.first['cipher_page_size']}');
```

## Technical Notes

1. The `PRAGMA cipher_page_size` must be set **before** the encryption key (`PRAGMA key`) is applied.
2. The page size setting only applies when creating a new database. It cannot be changed on existing databases.
3. The cipher_migrate feature (for migrating databases from SQLCipher 3.x to 4.x) is still supported and will work with the 16 KB page size.

## References

- [SQLCipher Documentation](https://www.zetetic.net/sqlcipher/sqlcipher-api/)
- [PRAGMA cipher_page_size](https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_page_size)
