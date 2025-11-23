import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.usersTable} (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone_number TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        user_type TEXT NOT NULL,
        profile_image_url TEXT,
        is_active INTEGER DEFAULT 1,
        is_approved INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create User Profiles table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.userProfilesTable} (
        user_id TEXT PRIMARY KEY,
        license_number TEXT,
        license_expiry TEXT,
        certifications TEXT,
        hourly_rate REAL,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        address TEXT,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Create Shifts table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.shiftsTable} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        location_id TEXT NOT NULL,
        location_name TEXT NOT NULL,
        location_address TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        hourly_rate REAL NOT NULL,
        required_guards INTEGER NOT NULL,
        assigned_guards INTEGER DEFAULT 0,
        required_sia_guards INTEGER,
        required_steward_guards INTEGER,
        status TEXT NOT NULL,
        shift_type TEXT NOT NULL,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        required_certifications TEXT,
        special_instructions TEXT,
        uniform_requirements TEXT,
        is_urgent INTEGER DEFAULT 0,
        FOREIGN KEY (created_by) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Create Shift Assignments table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.shiftAssignmentsTable} (
        id TEXT PRIMARY KEY,
        shift_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        status TEXT NOT NULL,
        assigned_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (shift_id) REFERENCES ${DatabaseConstants.shiftsTable} (id),
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Create Payroll Entries table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.payrollEntriesTable} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        shift_id TEXT NOT NULL,
        shift_title TEXT NOT NULL,
        shift_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        hours_worked REAL NOT NULL,
        hourly_rate REAL NOT NULL,
        total_pay REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        confirmed_at TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id),
        FOREIGN KEY (shift_id) REFERENCES ${DatabaseConstants.shiftsTable} (id)
      )
    ''');

    // Create Company Codes table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.companyCodesTable} (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        company_name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        expires_at TEXT,
        created_by TEXT NOT NULL,
        max_uses INTEGER DEFAULT 100,
        current_uses INTEGER DEFAULT 0,
        FOREIGN KEY (created_by) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Create Bookings table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.bookingsTable} (
        id TEXT PRIMARY KEY,
        shift_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        status TEXT NOT NULL,
        booking_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (shift_id) REFERENCES ${DatabaseConstants.shiftsTable} (id),
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_shifts_status ON ${DatabaseConstants.shiftsTable} (status)');
    await db.execute('CREATE INDEX idx_shifts_type ON ${DatabaseConstants.shiftsTable} (shift_type)');
    await db.execute('CREATE INDEX idx_shifts_created_by ON ${DatabaseConstants.shiftsTable} (created_by)');
    await db.execute('CREATE INDEX idx_assignments_shift_id ON ${DatabaseConstants.shiftAssignmentsTable} (shift_id)');
    await db.execute('CREATE INDEX idx_assignments_user_id ON ${DatabaseConstants.shiftAssignmentsTable} (user_id)');
    await db.execute('CREATE INDEX idx_payroll_user_id ON ${DatabaseConstants.payrollEntriesTable} (user_id)');
    await db.execute('CREATE INDEX idx_bookings_user_id ON ${DatabaseConstants.bookingsTable} (user_id)');
    await db.execute('CREATE INDEX idx_bookings_shift_id ON ${DatabaseConstants.bookingsTable} (shift_id)');

    // Create messages table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.messagesTable} (
        id TEXT PRIMARY KEY,
        from_user_id TEXT NOT NULL,
        from_user_name TEXT NOT NULL,
        from_user_email TEXT NOT NULL,
        to_user_id TEXT NOT NULL,
        subject TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        reply_to_message_id TEXT,
        FOREIGN KEY (from_user_id) REFERENCES ${DatabaseConstants.usersTable} (id),
        FOREIGN KEY (to_user_id) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Create indexes for messages
    await db.execute('CREATE INDEX idx_messages_to_user ON ${DatabaseConstants.messagesTable} (to_user_id)');
    await db.execute('CREATE INDEX idx_messages_from_user ON ${DatabaseConstants.messagesTable} (from_user_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON ${DatabaseConstants.messagesTable} (created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE ${DatabaseConstants.usersTable} ADD COLUMN is_approved INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ${DatabaseConstants.shiftsTable} ADD COLUMN required_sia_guards INTEGER');
      await db.execute('ALTER TABLE ${DatabaseConstants.shiftsTable} ADD COLUMN required_steward_guards INTEGER');
    }
    
    if (oldVersion < 3) {
      // Add messages table for version 3
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.messagesTable} (
          id TEXT PRIMARY KEY,
          from_user_id TEXT NOT NULL,
          from_user_name TEXT NOT NULL,
          from_user_email TEXT NOT NULL,
          to_user_id TEXT NOT NULL,
          subject TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          is_read INTEGER DEFAULT 0,
          reply_to_message_id TEXT,
          FOREIGN KEY (from_user_id) REFERENCES ${DatabaseConstants.usersTable} (id),
          FOREIGN KEY (to_user_id) REFERENCES ${DatabaseConstants.usersTable} (id)
        )
      ''');
      
      await db.execute('CREATE INDEX idx_messages_to_user ON ${DatabaseConstants.messagesTable} (to_user_id)');
      await db.execute('CREATE INDEX idx_messages_from_user ON ${DatabaseConstants.messagesTable} (from_user_id)');
      await db.execute('CREATE INDEX idx_messages_created_at ON ${DatabaseConstants.messagesTable} (created_at)');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
