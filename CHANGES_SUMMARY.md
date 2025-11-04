# Summary of Changes - 16 KB Page Size Support

## Version
Updated from **3.4.0** to **3.5.0**

## Modified Files

### 1. `/sqflite/android/src/main/java/com/davidmartos96/sqflite_sqlcipher/Database.java`
**Changes:**
- Added `PRAGMA cipher_page_size = 16384` in the `preKey()` method of `SQLiteDatabaseHook`
- Applied to both normal database opening and database migration scenarios
- Ensures page size is set BEFORE the encryption key is applied

**Key code:**
```java
@Override
public void preKey(SQLiteConnection database) {
    // Set page size to 16KB before key is set
    database.executeForLong("PRAGMA cipher_page_size = 16384;", null, null);
}
```

### 2. `/sqflite/ios/Classes/SqfliteSqlCipherPlugin.m`
**Changes:**
- Added `PRAGMA cipher_page_size = 16384` execution before setting the encryption key
- Applied in the `handleOpenDatabaseCall` method

**Key code:**
```objectivec
// Set page size to 16KB before setting the key
[database executeUpdate:@"PRAGMA cipher_page_size = 16384"];

if (password == nil) {
    [database setKey:@""];
} else {
    [database setKey:password];
}
```

### 3. `/sqflite/macos/Classes/SqfliteSqlCipherPlugin.m`
**Changes:**
- Same as iOS implementation
- Added `PRAGMA cipher_page_size = 16384` before setting the key

### 4. `/sqflite/README.md`
**Changes:**
- Added documentation about 16 KB page size support
- Explained the benefits of using larger page sizes

### 5. `/sqflite/CHANGELOG.md`
**Changes:**
- Added entry for version 3.5.0
- Documented the new 16 KB page size support feature

### 6. `/sqflite/pubspec.yaml`
**Changes:**
- Updated version from 3.4.0 to 3.5.0

## New Files Created

### 1. `/16KB_PAGE_SIZE.md`
Comprehensive documentation covering:
- Overview of 16 KB page size support
- Benefits and rationale
- Implementation details for each platform
- Compatibility notes
- Migration guide for existing databases
- Verification methods
- Technical notes and references

### 2. `/sqflite/test/page_size_16kb_test.dart`
Test suite to verify:
- New databases use 16 KB page size
- Database operations work correctly
- Batch operations function properly
- Transactions work as expected

## Technical Details

### Why Set Page Size Before Key?
According to SQLCipher documentation, `PRAGMA cipher_page_size` must be set **before** the encryption key (`PRAGMA key`) is applied. This is because:
1. The page size affects how data is encrypted and stored
2. Once the key is set, the encryption parameters are locked in
3. Setting page size after the key would have no effect

### Platform-Specific Implementation

**Android:**
- Uses `SQLiteDatabaseHook` with `preKey()` callback
- Applied to both normal opening and cipher_migrate scenarios
- Uses `database.executeForLong()` to execute the PRAGMA statement

**iOS/macOS:**
- Uses FMDB's `executeUpdate` method
- Applied before calling `setKey`
- Simpler implementation due to FMDB's API design

## Benefits of 16 KB Page Size

1. **Performance**: Better I/O efficiency with fewer disk operations
2. **Compatibility**: Aligns with modern storage systems (SSDs, flash storage)
3. **Apple Platforms**: Better alignment with APFS 4 KB blocks
4. **Future-Proof**: Follows industry trends toward larger page sizes

## Important Notes for Users

### New Databases
- Automatically use 16 KB page size
- No configuration required
- Works out of the box

### Existing Databases
- **Will NOT be affected** - they keep their original page size
- To use 16 KB on existing databases, must:
  1. Create a new database
  2. Migrate all data
  3. Replace the old database

### Backward Compatibility
- This change is fully backward compatible
- Existing databases continue to work without modification
- Only NEW databases created with version 3.5.0+ use 16 KB pages

## Testing Recommendations

Before deploying to production:

1. Test database creation and opening
2. Verify all CRUD operations work
3. Test batch operations and transactions
4. Check performance with real-world data sizes
5. Test on all target platforms (Android, iOS, macOS)

## Migration Path (If Needed)

If you need to migrate existing databases to 16 KB:

```dart
// See 16KB_PAGE_SIZE.md for complete migration example
// Key steps:
// 1. Open old database
// 2. Create new database (automatically uses 16 KB)
// 3. Copy schema and data
// 4. Replace old database file
```

## References

- [SQLCipher Documentation](https://www.zetetic.net/sqlcipher/sqlcipher-api/)
- [PRAGMA cipher_page_size](https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_page_size)
- [SQLCipher Page Size Considerations](https://www.zetetic.net/sqlcipher/design/)
