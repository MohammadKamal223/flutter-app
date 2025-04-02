import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  PostgreSQLConnection? _connection;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<void> connect() async {
    _connection ??= PostgreSQLConnection(
      '192.168.100.76',
      5432,
      'flutter_App',
      username: 'postgres',
      password: 'bleach.1997',
    );

    try {
      await _connection!.open();
      print("✅ Connected to PostgreSQL database.");
      await _createTables();
    } catch (e) {
      print("❌ Database connection error: $e");
    }
  }

  Future<void> _createTables() async {
    try {
      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          email VARCHAR(255) UNIQUE NOT NULL,
          password TEXT NOT NULL,
          name VARCHAR(255) NOT NULL,
          language VARCHAR(10) CHECK (language IN ('en', 'ar')) NOT NULL
        );
      ''');

      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS admins (
          id SERIAL PRIMARY KEY,
          work_id VARCHAR(50) UNIQUE NOT NULL,
          email VARCHAR(255) UNIQUE NOT NULL,
          password TEXT NOT NULL,
          name VARCHAR(255) NOT NULL
        );
      ''');

      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS logs (
          id SERIAL PRIMARY KEY,
          admin_email VARCHAR(255) REFERENCES admins(email) ON DELETE CASCADE,
          login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      print("✅ Tables ensured.");
    } catch (e) {
      print("❌ Error creating tables: $e");
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ✅ Register User
  Future<int?> registerUser(String email, String password, String name, String language) async {
    try {
      var result = await _connection!.query(
        "INSERT INTO users (email, password, name, language) VALUES (@email, @password, @name, @language) RETURNING id",
        substitutionValues: {
          "email": email,
          "password": _hashPassword(password),
          "name": name,
          "language": language,
        },
      );
      return result.isNotEmpty ? result[0][0] as int : null;
    } catch (e) {
      print("❌ Error registering user: $e");
      return null;
    }
  }

  // ✅ Register Admin (Now includes work_id)
  Future<int?> registerAdmin(String workId, String email, String password, String name) async {
    try {
      var result = await _connection!.query(
        "INSERT INTO admins (work_id, email, password, name) VALUES (@work_id, @email, @password, @name) RETURNING id",
        substitutionValues: {
          "work_id": workId,
          "email": email,
          "password": _hashPassword(password),
          "name": name,
        },
      );
      return result.isNotEmpty ? result[0][0] as int : null;
    } catch (e) {
      print("❌ Error registering admin: $e");
      return null;
    }
  }

  // ✅ User Login
  Future<bool> loginUser(String email, String password) async {
    try {
      var result = await _connection!.query(
        "SELECT password FROM users WHERE email = @email",
        substitutionValues: {"email": email},
      );

      if (result.isNotEmpty) {
        String storedPassword = result[0][0] as String;
        return storedPassword == _hashPassword(password);
      }
      return false;
    } catch (e) {
      print("❌ Error logging in user: $e");
      return false;
    }
  }

  // ✅ Admin Login (Requires Work ID)
  Future<bool> loginAdmin(String workId, String email, String password) async {
    try {
      var result = await _connection!.query(
        "SELECT password FROM admins WHERE work_id = @work_id AND email = @email",
        substitutionValues: {"work_id": workId, "email": email},
      );

      if (result.isNotEmpty) {
        String storedPassword = result[0][0] as String;
        if (storedPassword == _hashPassword(password)) {
          await _logAdminLogin(email);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("❌ Error logging in admin: $e");
      return false;
    }
  }

  // ✅ Log Admin Login Time
  Future<void> _logAdminLogin(String email) async {
    try {
      await _connection!.query(
        "INSERT INTO logs (admin_email, login_time) VALUES (@admin_email, NOW())",
        substitutionValues: {"admin_email": email},
      );
    } catch (e) {
      print("❌ Error logging admin login: $e");
    }
  }

  // ✅ Fetch Admin Login Logs
  Future<List<Map<String, dynamic>>> getAdminLogs() async {
    try {
      var result = await _connection!.query("SELECT admin_email, login_time FROM logs ORDER BY login_time DESC");
      return result.map((row) => {"admin_email": row[0], "login_time": row[1]}).toList();
    } catch (e) {
      print("❌ Error fetching admin logs: $e");
      return [];
    }
  }

  // ✅ Reset User Password
  Future<bool> resetUserPassword(String email, String newPassword) async {
    try {
      var result = await _connection!.query(
        "UPDATE users SET password = @password WHERE email = @email RETURNING id",
        substitutionValues: {"email": email, "password": _hashPassword(newPassword)},
      );
      return result.isNotEmpty;
    } catch (e) {
      print("❌ Error resetting user password: $e");
      return false;
    }
  }

  // ✅ Reset Admin Password (Requires Work ID)
  Future<bool> resetAdminPassword(String workId, String email, String newPassword) async {
    try {
      var result = await _connection!.query(
        "UPDATE admins SET password = @password WHERE work_id = @work_id AND email = @email RETURNING id",
        substitutionValues: {"work_id": workId, "email": email, "password": _hashPassword(newPassword)},
      );
      return result.isNotEmpty;
    } catch (e) {
      print("❌ Error resetting admin password: $e");
      return false;
    }
  }
}
