import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class DriveService {
  static final DriveService _instance = DriveService._internal();
  drive.DriveApi? _driveApi;
  static const _scopes = [drive.DriveApi.driveFileScope];

  factory DriveService() {
    return _instance;
  }

  DriveService._internal();

  Future<void> _init() async {
    if (_driveApi != null) return;

    try {
      // Load the service account credentials JSON file
      final credentialsJson = await rootBundle
          .loadString('assets/engineering-460514-495241aefeb9.json');
      final credentials =
          ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));

      final client = await clientViaServiceAccount(credentials, _scopes);
      _driveApi = drive.DriveApi(client);
    } catch (e) {
      print('Error initializing Drive API: $e');
      throw Exception('Failed to initialize Google Drive API: $e');
    }
  }

  Future<String> uploadFile(File file, String filename, String mimeType) async {
    await _init();

    if (_driveApi == null) {
      throw Exception('Drive API not initialized');
    }

    try {
      // Create a unique filename to avoid conflicts
      final uniqueFilename =
          '${DateTime.now().millisecondsSinceEpoch}_$filename';

      // Create file metadata - using a folder that's accessible
      final fileMedia = drive.File()
        ..name = uniqueFilename
        ..description = 'Uploaded from Engineering App'
        ..mimeType = mimeType;

      // Upload file
      final media = drive.Media(file.openRead(), file.lengthSync());
      final driveFile = await _driveApi!.files.create(
        fileMedia,
        uploadMedia: media,
        $fields: 'id,webContentLink,webViewLink',
      );

      // Make the file viewable to anyone with the link
      await _driveApi!.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        driveFile.id!,
      );

      // Get direct download link
      final fileId = driveFile.id!;
      // Construct direct download link (needs to be constructed in this format)
      final directLink = 'https://drive.google.com/uc?export=view&id=$fileId';

      print('Uploaded file to Drive: $directLink');
      return directLink;
    } catch (e) {
      print('Error uploading file to Drive: $e');
      throw Exception('Failed to upload file to Google Drive: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    await _init();

    if (_driveApi == null) {
      throw Exception('Drive API not initialized');
    }

    try {
      // Extract file ID from the URL
      final fileId = getFileIdFromUrl(fileUrl);
      if (fileId == null) {
        throw Exception('Invalid file URL');
      }

      await _driveApi!.files.delete(fileId);
    } catch (e) {
      print('Error deleting file from Drive: $e');
      throw Exception('Failed to delete file from Google Drive: $e');
    }
  }

  // Extract file ID from Google Drive URL
  static String? getFileIdFromUrl(String url) {
    if (url.isEmpty) return null;

    // Handle direct access links
    if (url.contains('drive.google.com/uc')) {
      final uri = Uri.parse(url);
      return uri.queryParameters['id'];
    }

    // Handle view links
    if (url.contains('drive.google.com/file/d/')) {
      final regex = RegExp(r'file/d/([^/]+)');
      final match = regex.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }
}
