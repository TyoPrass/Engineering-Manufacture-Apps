import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engginering/services/drive_service.dart';
import 'package:path/path.dart' as p;

class TrialModel {
  final String id;
  final String namaCustomer;
  final String namaPart;
  final String noPart;
  final String proses;
  final String noProject;
  final String matSpec;
  final String matSize;
  final String mcName;
  final String mcCapacity;
  final String dhHeight;
  final String problemTool;
  final String analisaTool;
  final String counterTool;
  final String problemPart;
  final String analisaPart;
  final String counterPart;
  final String imagePath;
  final String videoPath;
  final String user;
  final String displayName;

  TrialModel({
    required this.id,
    required this.namaCustomer,
    required this.namaPart,
    required this.noPart,
    required this.proses,
    required this.noProject,
    required this.matSpec,
    required this.matSize,
    required this.mcName,
    required this.mcCapacity,
    required this.dhHeight,
    required this.problemTool,
    required this.analisaTool,
    required this.counterTool,
    required this.problemPart,
    required this.analisaPart,
    required this.counterPart,
    required this.imagePath,
    required this.videoPath,
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
          : fileName.endsWith('.mp4')
              ? 'video/mp4'
              : 'application/octet-stream';

      return await driveService.uploadFile(file, fileName, mimeType);
    } catch (e) {
      throw Exception("Failed to upload file to Google Drive: $e");
    }
  }

  // Updated method to upload media files to Google Drive
  static Future<Map<String, String>> uploadMediaFiles({
    required File? imageFile,
    required File? videoFile,
  }) async {
    final Map<String, String> mediaUrls = {};

    if (imageFile != null) {
      final imageUrl = await uploadFileToGoogleDrive(imageFile);
      mediaUrls['imagePath'] = imageUrl;
    }

    if (videoFile != null) {
      final videoUrl = await uploadFileToGoogleDrive(videoFile);
      mediaUrls['videoPath'] = videoUrl;
    }

    return mediaUrls;
  }

  // Method to convert model to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'nama_customer': namaCustomer,
      'nama_part': namaPart,
      'no_part': noPart,
      'proses': proses,
      'no_project': noProject,
      'mat_spec': matSpec,
      'mat_size': matSize,
      'mc_name': mcName,
      'mc_capacity': mcCapacity,
      'dh_height': dhHeight,
      'problem_tool': problemTool,
      'analisa_tool': analisaTool,
      'counter_tool': counterTool,
      'problem_part': problemPart,
      'analisa_part': analisaPart,
      'counter_part': counterPart,
      'image': imagePath, // Store Google Drive URL
      'video': videoPath, // Store Google Drive URL
      'user': user,
      'display_name': displayName,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // Static method to create a new trial with media files
  static Future<void> createTrialWithMedia({
    required Map<String, dynamic> trialData,
    required File? imageFile,
    required File? videoFile,
  }) async {
    try {
      // Upload media files first
      final mediaUrls = await uploadMediaFiles(
        imageFile: imageFile,
        videoFile: videoFile,
      );

      // Add the document with media URLs
      await FirebaseFirestore.instance.collection('Trial').add({
        ...trialData,
        'image': mediaUrls['imagePath'] ?? '',
        'video': mediaUrls['videoPath'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to create trial with media: $e");
    }
  }

  factory TrialModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TrialModel(
      id: doc.id,
      namaCustomer: data['nama_customer'] ?? '',
      namaPart: data['nama_part'] ?? '',
      noPart: data['no_part'] ?? '',
      proses: data['proses'] ?? '',
      noProject: data['no_project'] ?? '',
      matSpec: data['mat_spec'] ?? '',
      matSize: data['mat_size'] ?? '',
      mcName: data['mc_name'] ?? '',
      mcCapacity: data['mc_capacity'] ?? '',
      dhHeight: data['dh_height'] ?? '',
      problemTool: data['problem_tool'] ?? '',
      analisaTool: data['analisa_tool'] ?? '',
      counterTool: data['counter_tool'] ?? '',
      problemPart: data['problem_part'] ?? '',
      analisaPart: data['analisa_part'] ?? '',
      counterPart: data['counter_part'] ?? '',
      imagePath: data['image'] ?? '', // Google Drive URL
      videoPath: data['video'] ?? '', // Google Drive URL
      user: data['user'] ?? '',
      displayName: data['display_name'] ?? '',
    );
  }

  String? get status => null;
}
