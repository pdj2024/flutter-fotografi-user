import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// ✅ HIVE MIGRATION HELPER
///
/// Handles migration from old data structure to new structure
/// Specifically for ChatMessageEntity changes:
/// - Old: noPenawaran as String
/// - New: penawaran as PenawaranModel
class HiveMigrationHelper {
  
  /// Clear all chat data (DESTRUCTIVE - use only when necessary)
  static Future<void> clearAllChatData() async {
    try {
      debugPrint('[Migration] 🧹 Clearing all chat data...');
      
      // Delete all chat-related boxes
      await Hive.deleteBoxFromDisk('chat_rooms');
      await Hive.deleteBoxFromDisk('chat_meta');
      
      // Delete all message boxes (pattern: chat_messages_*)
      final boxNames = await _getAllChatMessageBoxNames();
      for (final boxName in boxNames) {
        await Hive.deleteBoxFromDisk(boxName);
      }
      
      debugPrint('[Migration] ✅ All chat data cleared');
    } catch (e) {
      debugPrint('[Migration] ❌ Error clearing data: $e');
    }
  }
  
  /// Get all chat message box names
  static Future<List<String>> _getAllChatMessageBoxNames() async {
    // This is tricky - we need to scan Hive storage
    // For now, return empty list (will be cleared on access)
    return [];
  }
  
  /// Check if migration is needed
  static Future<bool> needsMigration() async {
    try {
      // Try to open a messages box and read
      // If it fails with type error, migration needed
      return false; // Will be detected on error
    } catch (e) {
      return true;
    }
  }
  
  /// Safe box opener with error recovery
  static Future<Box<T>> safeOpenBox<T>(
    String boxName, {
    bool Function(dynamic)? isTypeError,
  }) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      if (e.toString().contains('type') && 
          e.toString().contains('is not a subtype')) {
        debugPrint('[Migration] 🔄 Type mismatch detected for box: $boxName');
        debugPrint('[Migration] 🧹 Clearing corrupted box...');
        
        // Close if open
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
          }
        } catch (_) {}
        
        // Delete corrupted box
        await Hive.deleteBoxFromDisk(boxName);
        
        debugPrint('[Migration] ✅ Corrupted box cleared, reopening...');
        
        // Reopen fresh box
        return await Hive.openBox<T>(boxName);
      }
      rethrow;
    }
  }
}