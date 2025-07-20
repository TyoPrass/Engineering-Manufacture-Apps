import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engginering/services/drive_service.dart';
import 'package:path/path.dart' as p;

class ToolingModel {
  final String id;
  final String mcName;
  final String namaPart; // Add nama_part field
  final String kapasitas;
  final String panjang;
  final String lebar;
  final String tinggi;
  final String imgFrontView;
  final String imgLowerDie;
  final String imgUpperDie;
  final String imgPartProses;
  final String user;
  final String displayName;

  ToolingModel({
    required this.id,
    required this.mcName,
    this.namaPart = '', // Initialize with empty string
    required this.kapasitas,
    required this.panjang,
    required this.lebar,
    required this.tinggi,
    required this.imgFrontView,
    required this.imgLowerDie,
    required this.imgUpperDie,
    required this.imgPartProses,
    required this.user,
    this.displayName = '',
  });

  // Method to upload file to Google Drive
  static Future<String> uploadFileToGoogleDrive(File file) async {
    try {
      final driveService = DriveService();
      final fileName = p.basename(file.path);
      final mimeType = fileName.endsWith('.jpg') ||
              fileName.endsWith('.jpeg') ||
              fileName.endsWith('.png')
          ? 'image/${p.extension(file.path).substring(1)}'
          : 'application/octet-stream';

      return await driveService.uploadFile(file, fileName, mimeType);
    } catch (e) {
      throw Exception("Failed to upload file to Google Drive: $e");
    }
  }

  // Updated method to upload images to Google Drive
  static Future<Map<String, String>> uploadMediaFiles({
    required File? imgFrontView,
    required File? imgLowerDie,
    required File? imgUpperDie,
    required File? imgPartProses,
  }) async {
    final Map<String, String> mediaUrls = {};

    if (imgFrontView != null) {
      mediaUrls['imgFrontView'] = await uploadFileToGoogleDrive(imgFrontView);
    }

    if (imgLowerDie != null) {
      mediaUrls['imgLowerDie'] = await uploadFileToGoogleDrive(imgLowerDie);
    }

    if (imgUpperDie != null) {
      mediaUrls['imgUpperDie'] = await uploadFileToGoogleDrive(imgUpperDie);
    }

    if (imgPartProses != null) {
      mediaUrls['imgPartProses'] = await uploadFileToGoogleDrive(imgPartProses);
    }

    return mediaUrls;
  }

  // Method to convert model to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'mc_name': mcName, // Changed from 'm/c_name' to 'mc_name'
      'nama_part': namaPart,
      'kapasitas': kapasitas,
      'panjang': panjang,
      'lebar': lebar,
      'tinggi': tinggi,
      'img_fv': imgFrontView, // Store Google Drive URL
      'img_ldv': imgLowerDie, // Store Google Drive URL
      'img_udv': imgUpperDie, // Store Google Drive URL
      'img_part': imgPartProses, // Store Google Drive URL
      'user': user,
      'display_name': displayName,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // Static method to create a new tooling with media files
  static Future<void> createToolingWithMedia({
    required Map<String, dynamic> toolingData,
    required File? imgFrontView,
    required File? imgLowerDie,
    required File? imgUpperDie,
    required File? imgPartProses,
  }) async {
    try {
      // Upload media files first
      final mediaUrls = await uploadMediaFiles(
        imgFrontView: imgFrontView,
        imgLowerDie: imgLowerDie,
        imgUpperDie: imgUpperDie,
        imgPartProses: imgPartProses,
      );

      // Add the document with media URLs
      await FirebaseFirestore.instance.collection('Tooling').add({
        ...toolingData,
        'img_fv': mediaUrls['imgFrontView'] ?? '',
        'img_ldv': mediaUrls['imgLowerDie'] ?? '',
        'img_udv': mediaUrls['imgUpperDie'] ?? '',
        'img_part': mediaUrls['imgPartProses'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to create tooling with media: $e");
    }
  }

  factory ToolingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ToolingModel(
      id: doc.id,
      // Use both field formats for backward compatibility
      mcName: data['mc_name'] ?? data['m/c_name'] ?? '',
      namaPart: data['nama_part'] ?? '',
      kapasitas: data['kapasitas'] ?? '',
      panjang: data['panjang'] ?? '',
      lebar: data['lebar'] ?? '',
      tinggi: data['tinggi'] ?? '',
      imgFrontView: data['img_fv'] ?? '', // Google Drive URL
      imgLowerDie: data['img_ldv'] ?? '', // Google Drive URL
      imgUpperDie: data['img_udv'] ?? '', // Google Drive URL
      imgPartProses: data['img_part'] ?? '', // Google Drive URL
      user: data['user'] ?? '',
      displayName: data['display_name'] ?? '',
    );
  }
}
