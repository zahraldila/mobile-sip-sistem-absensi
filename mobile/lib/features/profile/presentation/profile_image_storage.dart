import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageStorage {
  static const String _profileImagePathKey = 'profile_image_path';

  Future<void> saveProfileImagePath(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, imagePath);
  }

  Future<String?> loadProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  Future<String> copyProfileImageToAppStorage(
    File sourceFile,
    String fileName,
  ) async {
    final appDir = await _appDirectory();
    final safeFileName = path.basename(fileName);
    final targetFile = File(path.join(appDir.path, safeFileName));
    await targetFile.parent.create(recursive: true);
    await sourceFile.copy(targetFile.path);
    return targetFile.path;
  }

  Future<Directory> _appDirectory() async {
    final appDirectory = await getApplicationSupportDirectory();
    final profileImagesDir = Directory(
      path.join(appDirectory.path, 'profile_images'),
    );
    if (!await profileImagesDir.exists()) {
      await profileImagesDir.create(recursive: true);
    }
    return profileImagesDir;
  }
}
