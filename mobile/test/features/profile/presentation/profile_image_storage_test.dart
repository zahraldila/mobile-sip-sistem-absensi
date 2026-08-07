import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/presentation/profile_image_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileImageStorage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and loads a profile image path', () async {
      final storage = ProfileImageStorage();
      const imagePath = '/tmp/profile_photo.png';

      await storage.saveProfileImagePath(imagePath);
      final loadedPath = await storage.loadProfileImagePath();

      expect(loadedPath, imagePath);
    });

    test('copies a file into app storage and returns the new path', () async {
      final storage = ProfileImageStorage();
      final tempDir = await Directory.systemTemp.createTemp('profile_test');
      final sourceFile = File('${tempDir.path}/source.png')
        ..writeAsStringSync('data');

      final copiedPath = await storage.copyProfileImageToAppStorage(
        sourceFile,
        tempDir.path,
      );

      final copiedFile = File(copiedPath);

      expect(copiedFile.existsSync(), isTrue);
      expect(copiedFile.readAsStringSync(), 'data');

      await copiedFile.delete();
      await sourceFile.delete();
      await tempDir.delete(recursive: true);
    });
  });
}
