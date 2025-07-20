import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:engginering/services/trial_service.dart';
import 'package:engginering/services/bookmark_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engginering/models/trial_model.dart';
import 'package:engginering/models/tooling_model.dart';
import 'package:engginering/widgets/drive_image_view.dart';
import 'package:engginering/widgets/drive_video_view.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({Key? key}) : super(key: key);

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  // Track which view is currently selected
  String _currentView = 'Trial';
  // Add BookmarkService
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom Navigation Bar
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentView = 'Trial';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 3,
                            color: _currentView == 'Trial'
                                ? Colors.green
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Trial',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _currentView == 'Trial'
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentView = 'Tooling';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 3,
                            color: _currentView == 'Tooling'
                                ? Colors.green
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Tooling',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _currentView == 'Tooling'
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: _currentView == 'Trial'
                ? _buildTrialView()
                : _buildToolingView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Trial')
                .orderBy('created_at',
                    descending: true) // Sort by timestamp, newest first
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No trial data available'),
                );
              }

              // Convert Firestore documents to TrialModel objects
              List<TrialModel> trials = snapshot.data!.docs.map((doc) {
                return TrialModel.fromFirestore(doc);
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: trials.length,
                  itemBuilder: (context, index) {
                    TrialModel trial = trials[index];
                    return _buildTrialCard(trial);
                  },
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TrialTaskPage(),
                  ),
                );
              },
              child: const Icon(Icons.add, size: 36),
              tooltip: 'Input Data',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard(TrialModel trial) {
    return FutureBuilder<bool>(
        future: _bookmarkService.isBookmarked('Trial', trial.id),
        builder: (context, snapshot) {
          bool isBookmarked = snapshot.data ?? false;

          return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrialDetailPage(trial: trial),
                    ),
                  ).then(
                      (_) => setState(() {})); // Refresh state when returning
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with menu button overlay
                    Stack(
                      children: [
                        // Image container
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                            ),
                            child: trial.imagePath.isNotEmpty
                                ? DriveImageView(
                                    url: trial.imagePath,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Icon(Icons.image, size: 60),
                                  ),
                          ),
                        ),
                        // Three-dot menu
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: _isCurrentUserUploader(trial.user)
                                ? PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editTrial(trial);
                                      } else if (value == 'delete') {
                                        _deleteTrial(trial.id);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit,
                                                color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : null, // Don't show menu button if not the uploader
                          ),
                        ),
                      ],
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Replace the Row containing status widget with just the part name
                          Text(
                            trial.namaPart,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _extractUsername(trial.user),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Part No : ${trial.noPart}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer : ${trial.namaCustomer}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Process: ${trial.proses}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          // Add bookmark button at the bottom
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () async {
                                  try {
                                    if (FirebaseAuth.instance.currentUser ==
                                        null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please log in to save items'),
                                        ),
                                      );
                                      return;
                                    }

                                    if (isBookmarked) {
                                      await _bookmarkService.removeBookmark(
                                          'Trial', trial.id);
                                    } else {
                                      await _bookmarkService.addBookmark(
                                          'Trial', trial.id);
                                    }
                                    setState(() {});
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Failed to save: $e')),
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: isBookmarked
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isBookmarked ? 'Saved' : 'Save',
                                      style: TextStyle(
                                        color: isBookmarked
                                            ? Colors.amber
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
        });
  }

  // Method to handle trial editing
  void _editTrial(TrialModel trial) {
    // Check permission before navigating
    if (!_isCurrentUserUploader(trial.user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit your own uploads')),
      );
      return;
    }

    // Navigate to edit page with the trial data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrialTaskPage(trialToEdit: trial),
      ),
    ).then((_) {
      // Refresh the state when returning from edit page
      setState(() {});
    });
  }

  // Method to handle trial deletion with confirmation dialog
  Future<void> _deleteTrial(String trialId) async {
    // Fetch the trial data to check permissions
    DocumentSnapshot trialDoc =
        await FirebaseFirestore.instance.collection('Trial').doc(trialId).get();

    if (!trialDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trial not found')),
      );
      return;
    }

    Map<String, dynamic> data = trialDoc.data() as Map<String, dynamic>;
    String uploaderEmail = data['user'] ?? '';

    if (!_isCurrentUserUploader(uploaderEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own uploads')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
                'Are you sure you want to delete this trial data? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        // Call delete service
        await FirebaseFirestore.instance
            .collection('Trial')
            .doc(trialId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trial data deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete trial data: $e')),
        );
      }
    }
  }

  Widget _buildToolingView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Tooling')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No tooling data available'),
                );
              }

              // Convert Firestore documents to ToolingModel objects
              List<ToolingModel> toolingItems = snapshot.data!.docs.map((doc) {
                return ToolingModel.fromFirestore(doc);
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: toolingItems.length,
                  itemBuilder: (context, index) {
                    ToolingModel tooling = toolingItems[index];
                    return _buildToolingCard(tooling);
                  },
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReportTaskPage(),
                  ),
                );
              },
              child: const Icon(Icons.add, size: 36),
              tooltip: 'Input Data',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolingCard(ToolingModel tooling) {
    return FutureBuilder<bool>(
        future: _bookmarkService.isBookmarked('Tooling', tooling.id),
        builder: (context, snapshot) {
          bool isBookmarked = snapshot.data ?? false;

          return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ToolingDetailPage(tooling: tooling),
                    ),
                  ).then(
                      (_) => setState(() {})); // Refresh state when returning
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with menu button overlay
                    Stack(
                      children: [
                        // Image container
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                            ),
                            child: tooling.imgFrontView.isNotEmpty
                                ? DriveImageView(
                                    url: tooling.imgFrontView,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Icon(Icons.image, size: 60),
                                  ),
                          ),
                        ),
                        // Three-dot menu
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: _isCurrentUserUploader(tooling.user)
                                ? PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editTooling(tooling);
                                      } else if (value == 'delete') {
                                        _deleteTooling(tooling.id);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit,
                                                color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : null, // Don't show menu button if not the uploader
                          ),
                        ),
                      ],
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Replace mcName with namaPart if available
                          Text(
                            tooling.namaPart.isNotEmpty
                                ? tooling.namaPart
                                : tooling.namaPart,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _extractUsername(tooling.user),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kapasitas: ${tooling.kapasitas}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dimensions: ${tooling.panjang} x ${tooling.lebar} x ${tooling.tinggi} mm',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          // Add bookmark button at the bottom
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () async {
                                  try {
                                    if (FirebaseAuth.instance.currentUser ==
                                        null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please log in to save items'),
                                        ),
                                      );
                                      return;
                                    }

                                    if (isBookmarked) {
                                      await _bookmarkService.removeBookmark(
                                          'Tooling', tooling.id);
                                    } else {
                                      await _bookmarkService.addBookmark(
                                          'Tooling', tooling.id);
                                    }
                                    setState(() {});
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Failed to save: $e')),
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: isBookmarked
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isBookmarked ? 'Saved' : 'Save',
                                      style: TextStyle(
                                        color: isBookmarked
                                            ? Colors.amber
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
        });
  }

  // Method to handle tooling editing
  void _editTooling(ToolingModel tooling) {
    if (!_isCurrentUserUploader(tooling.user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit your own uploads')),
      );
      return;
    }

    // Navigate to edit page with the tooling data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportTaskPage(toolingToEdit: tooling),
      ),
    ).then((_) {
      // Refresh the state when returning from edit page
      setState(() {});
    });
  }

  // Method to handle tooling deletion with confirmation dialog
  Future<void> _deleteTooling(String toolingId) async {
    // Fetch the tooling data to check permissions
    DocumentSnapshot toolingDoc = await FirebaseFirestore.instance
        .collection('Tooling')
        .doc(toolingId)
        .get();

    if (!toolingDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tooling not found')),
      );
      return;
    }

    Map<String, dynamic> data = toolingDoc.data() as Map<String, dynamic>;
    String uploaderEmail = data['user'] ?? '';

    if (!_isCurrentUserUploader(uploaderEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own uploads')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
                'Are you sure you want to delete this tooling data? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        // Call delete service
        await FirebaseFirestore.instance
            .collection('Tooling')
            .doc(toolingId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tooling data deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete tooling data: $e')),
        );
      }
    }
  }

  // Helper method to extract username from email
  String _extractUsername(String email) {
    if (email.isEmpty) return 'Unknown User';
    // Extract the part before @ in the email
    return email.split('@')[0];
  }

  // Helper method to check if current user is the uploader
  bool _isCurrentUserUploader(String uploaderEmail) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.email == uploaderEmail;
  }
}

class TrialTaskPage extends StatefulWidget {
  final TrialModel? trialToEdit;

  const TrialTaskPage({Key? key, this.trialToEdit}) : super(key: key);

  @override
  State<TrialTaskPage> createState() => _TrialTaskPageState();
}

class _TrialTaskPageState extends State<TrialTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _partNameController = TextEditingController();
  final _partNoController = TextEditingController();
  final _processController = TextEditingController();
  final _projectNoController = TextEditingController();
  final _matSpecController = TextEditingController();
  final _matSizeController = TextEditingController();
  final _mcNameController = TextEditingController();
  final _mcCapacityController = TextEditingController();
  final _dhHeightController = TextEditingController();
  final TrialService _trialService = TrialService();

  // Add variables for image and video
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  File? _videoFile;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;

  final _problemToolController = TextEditingController();
  final _analisaToolController = TextEditingController();
  final _counterToolController = TextEditingController();
  final _problemPartController = TextEditingController();
  final _analisaPartController = TextEditingController();
  final _counterPartController = TextEditingController();

  // Add status variable
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Initialize status with default value
    _selectedStatus = 'open';
    if (widget.trialToEdit != null) {
      _loadTrialData(widget.trialToEdit!);
    }
  }

  void _loadTrialData(TrialModel trial) {
    _customerController.text = trial.namaCustomer;
    _partNameController.text = trial.namaPart;
    _partNoController.text = trial.noPart;
    _processController.text = trial.proses;
    _projectNoController.text = trial.noProject;
    _matSpecController.text = trial.matSpec;
    _matSizeController.text = trial.matSize;
    _mcNameController.text = trial.mcName;
    _mcCapacityController.text = trial.mcCapacity;
    _dhHeightController.text = trial.dhHeight;
    _problemToolController.text = trial.problemTool;
    _analisaToolController.text = trial.analisaTool;
    _counterToolController.text = trial.counterTool;
    _problemPartController.text = trial.problemPart;
    _analisaPartController.text = trial.analisaPart;
    _counterPartController.text = trial.counterPart;

    // Safely load status with proper error handling
    try {
      String? statusValue = trial.status;
      if (statusValue != null &&
          (statusValue == 'open' || statusValue == 'close')) {
        _selectedStatus = statusValue;
      } else {
        _selectedStatus = 'open'; // Default value
      }
    } catch (e) {
      print("Error loading status: $e");
      _selectedStatus = 'open'; // Fallback to default
    }

    if (trial.imagePath.isNotEmpty) {
      _imageFile = File(trial.imagePath);
    }
    if (trial.videoPath.isNotEmpty) {
      _videoFile = File(trial.videoPath);
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _partNameController.dispose();
    _partNoController.dispose();
    _processController.dispose();
    _projectNoController.dispose();
    _matSpecController.dispose();
    _matSizeController.dispose();
    _mcNameController.dispose();
    _mcCapacityController.dispose();
    _dhHeightController.dispose();
    _videoPlayerController?.dispose();
    _problemToolController.dispose();
    _analisaToolController.dispose();
    _counterToolController.dispose();
    _problemPartController.dispose();
    _analisaPartController.dispose();
    _counterPartController.dispose();
    super.dispose();
  }

  // Method to pick image from gallery or camera with better error handling
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress untuk mengurangi ukuran
      );
      if (pickedFile != null) {
        // Salin file ke lokasi aplikasi untuk mengatasi masalah scoped storage di Android 10+
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final String fileName =
            DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
        final File localImage = File('${directory.path}/$fileName');

        final imageTemp = File(pickedFile.path);
        final imageBytes = await imageTemp.readAsBytes();
        await localImage.writeAsBytes(imageBytes);

        setState(() {
          _imageFile = localImage;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: ${e.toString()}')),
      );
    }
  }

  // Method to pick video from gallery or camera with better error handling
  Future<void> _pickVideo(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1), // Batasi durasi video
      );
      if (pickedFile != null) {
        // Salin file ke lokasi aplikasi untuk mengatasi masalah scoped storage di Android 10+
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final String fileName =
            DateTime.now().millisecondsSinceEpoch.toString() + '.mp4';
        final File localVideo = File('${directory.path}/$fileName');

        final videoTemp = File(pickedFile.path);
        final videoBytes = await videoTemp.readAsBytes();
        await localVideo.writeAsBytes(videoBytes);

        setState(() {
          _videoFile = localVideo;
          _initializeVideoPlayer();
        });
      }
    } catch (e) {
      print("Error picking video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil video: ${e.toString()}')),
      );
    }
  }

  // Initialize video player
  void _initializeVideoPlayer() {
    if (_videoFile != null) {
      _videoPlayerController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  // Show options to select camera or gallery
  void _showImageSourceOptions(BuildContext context, bool isVideo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.of(context).pop();
              if (isVideo) {
                _pickVideo(ImageSource.camera);
              } else {
                _pickImage(ImageSource.camera);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.of(context).pop();
              if (isVideo) {
                _pickVideo(ImageSource.gallery);
              } else {
                _pickImage(ImageSource.gallery);
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      // Extract username from email
      String userEmail = user?.email ?? 'unknown@example.com';
      String username = userEmail.split('@')[0];

      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Saving data, please wait...")
                  ],
                ),
              ),
            );
          },
        );

        Map<String, String> mediaUrls = {};

        // Try to upload media files to Google Drive with error handling
        try {
          mediaUrls = await TrialModel.uploadMediaFiles(
            imageFile: _imageFile,
            videoFile: _videoFile,
          );
        } catch (uploadError) {
          print("Warning: Upload to Google Drive failed: $uploadError");
          // Use local paths as fallback
          if (_imageFile != null) {
            mediaUrls['imagePath'] = _imageFile!.path;
          }
          if (_videoFile != null) {
            mediaUrls['videoPath'] = _videoFile!.path;
          }
        }

        // Create base data with URLs or local paths
        final data = {
          'nama_customer': _customerController.text,
          'nama_part': _partNameController.text,
          'no_part': _partNoController.text,
          'proses': _processController.text,
          'no_project': _projectNoController.text,
          'mat_spec': _matSpecController.text,
          'mat_size': _matSizeController.text,
          'mc_name': _mcNameController.text,
          'mc_capacity': _mcCapacityController.text,
          'dh_height': _dhHeightController.text,
          'user': userEmail,
          'display_name': username,
          'image': mediaUrls['imagePath'] ?? '',
          'video': mediaUrls['videoPath'] ?? '',
          'problem_tool': _problemToolController.text,
          'analisa_tool': _analisaToolController.text,
          'counter_tool': _counterToolController.text,
          'problem_part': _problemPartController.text,
          'analisa_part': _analisaPartController.text,
          'counter_part': _counterPartController.text,
          'status': _selectedStatus ?? 'open', // Add status field with fallback
        };

        // Hide loading dialog
        Navigator.pop(context);

        if (widget.trialToEdit != null) {
          // Update existing trial data
          await FirebaseFirestore.instance
              .collection('Trial')
              .doc(widget.trialToEdit!.id)
              .update({
            ...data,
            'updated_at': FieldValue.serverTimestamp(),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data updated successfully')),
          );
        } else {
          // Save new trial data - directly to Firestore with timestamps
          await FirebaseFirestore.instance.collection('Trial').add({
            ...data,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data saved successfully')),
          );
        }
        Navigator.of(context).pop(); // Return to the previous page
      } catch (e) {
        // Hide loading dialog if still showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        print("Error saving data: $e"); // Log error for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trial Task Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trial List Part',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Upload Image',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 16, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: ElevatedButton(
                          onPressed: () =>
                              _showImageSourceOptions(context, false),
                          child: const Text('Choose Image'),
                        ),
                      ),
              ),
              const SizedBox(
                height: 20,
              ),

              // Video Upload Section
              const Text('Upload Video',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _videoFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _videoPlayerController != null &&
                                  _videoPlayerController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoPlayerController!.value.aspectRatio,
                                  child: VideoPlayer(_videoPlayerController!),
                                )
                              : const Center(
                                  child: CircularProgressIndicator()),
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isVideoPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_videoPlayerController!
                                          .value.isPlaying) {
                                        _videoPlayerController!.pause();
                                        _isVideoPlaying = false;
                                      } else {
                                        _videoPlayerController!.play();
                                        _isVideoPlaying = true;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 16, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _videoPlayerController?.dispose();
                                    _videoPlayerController = null;
                                    _videoFile = null;
                                    _isVideoPlaying = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: ElevatedButton(
                          onPressed: () =>
                              _showImageSourceOptions(context, true),
                          child: const Text('Choose Video'),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              const Text('Nama Customer',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(
                  hintText: 'Nama Customer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Nama Part',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _partNameController,
                decoration: const InputDecoration(
                  hintText: 'Part Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Nomor Part',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _partNoController,
                decoration: const InputDecoration(
                  hintText: 'Part No',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Proses',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _processController,
                decoration: const InputDecoration(
                  hintText: 'Process',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('No Project',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _projectNoController,
                decoration: const InputDecoration(
                  hintText: 'Project No',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Mat Spec',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _matSpecController,
                decoration: const InputDecoration(
                  hintText: 'Material Specification',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Mat Size',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _matSizeController,
                decoration: const InputDecoration(
                  hintText: 'Material Size',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('M/C Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _mcNameController,
                decoration: const InputDecoration(
                  hintText: 'Machine Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('M/C Capacity',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _mcCapacityController,
                decoration: const InputDecoration(
                  hintText: 'Machine Capacity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('DH Dies',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _dhHeightController,
                decoration: const InputDecoration(
                  hintText: 'DH Height',
                  border: OutlineInputBorder(),
                ),
              ),

              // Problem Tools / Dies
              const SizedBox(height: 20),
              const Text(
                'Problem Tools  (Dies Machine)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Problem Tool',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _problemToolController,
                decoration: const InputDecoration(
                  hintText: 'Enter problem with tools or dies',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              const Text('Analisa Penyebab',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _analisaToolController,
                decoration: const InputDecoration(
                  hintText: 'Enter root cause analysis',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              const Text('Counter Measure',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _counterToolController,
                decoration: const InputDecoration(
                  hintText: 'Enter counter measures taken',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Problem Part / Hasil Part section header
              const Text(
                'Problem Part  (Hasil Part)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),
              const Text('Problem Part',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _problemPartController,
                decoration: const InputDecoration(
                  hintText: 'Enter problem with parts',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              const Text('Analisa Penyebab',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _analisaPartController,
                decoration: const InputDecoration(
                  hintText: 'Enter root cause analysis',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              const Text('Counter Measure',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _counterPartController,
                decoration: const InputDecoration(
                  hintText: 'Enter counter measures taken',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 20),
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                value: _selectedStatus, // Set the current value
                hint: const Text('Pilih Open/Close'),
                items: const [
                  DropdownMenuItem(
                    value: 'open',
                    child: Text('Open'),
                  ),
                  DropdownMenuItem(
                    value: 'close',
                    child: Text('Close'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select Open or Close';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Submit', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportTaskPage extends StatefulWidget {
  final ToolingModel? toolingToEdit;

  const ReportTaskPage({Key? key, this.toolingToEdit}) : super(key: key);

  @override
  State<ReportTaskPage> createState() => _ReportTaskPageState();
}

// Page Tooling Album
class _ReportTaskPageState extends State<ReportTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();
  final _mcNameController = TextEditingController();
  final _namaPartController =
      TextEditingController(); // Add nama_part controller
  final _panjangController = TextEditingController();
  final _lebarController = TextEditingController();
  final _tinggiController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _frontViewImage;
  File? _lowerDieImage;
  File? _upperDieImage;
  File? _partProsesImage;

  bool _isEditing = false;
  String? _docId;

  @override
  void initState() {
    super.initState();
    // If we're editing, populate the form with existing data
    if (widget.toolingToEdit != null) {
      _populateForm();
      _isEditing = true;
      _docId = widget.toolingToEdit!.id;
    }
  }

  // Populate form with existing tooling data
  void _populateForm() {
    final tooling = widget.toolingToEdit!;
    _capacityController.text = tooling.kapasitas;
    _mcNameController.text = tooling.mcName;
    _namaPartController.text = tooling.namaPart; // Load nama_part
    _panjangController.text = tooling.panjang;
    _lebarController.text = tooling.lebar;
    _tinggiController.text = tooling.tinggi;

    // Set images if they exist
    if (tooling.imgFrontView.isNotEmpty) {
      _frontViewImage = File(tooling.imgFrontView);
    }

    if (tooling.imgLowerDie.isNotEmpty) {
      _lowerDieImage = File(tooling.imgLowerDie);
    }

    if (tooling.imgUpperDie.isNotEmpty) {
      _upperDieImage = File(tooling.imgUpperDie);
    }

    if (tooling.imgPartProses.isNotEmpty) {
      _partProsesImage = File(tooling.imgPartProses);
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _mcNameController.dispose();
    _namaPartController.dispose(); // Dispose nama_part controller
    _panjangController.dispose();
    _lebarController.dispose();
    _tinggiController.dispose();
    super.dispose();
  }

  // Method to pick image from gallery or camera
  Future<void> _pickImage(ImageSource source, int imageType) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress to reduce size
      );
      if (pickedFile != null) {
        // Copy file to app location to handle scoped storage on Android 10+
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final String fileName =
            DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
        final File localImage = File('${directory.path}/$fileName');

        final imageTemp = File(pickedFile.path);
        final imageBytes = await imageTemp.readAsBytes();
        await localImage.writeAsBytes(imageBytes);

        setState(() {
          switch (imageType) {
            case 1:
              _frontViewImage = localImage;
              break;
            case 2:
              _lowerDieImage = localImage;
              break;
            case 3:
              _upperDieImage = localImage;
              break;
            case 4:
              _partProsesImage = localImage;
              break;
          }
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: ${e.toString()}')),
      );
    }
  }

  // Show options to select camera or gallery
  void _showImageSourceOptions(BuildContext context, int imageType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera, imageType);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery, imageType);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection(
      String title, File? imageFile, int imageType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: imageFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 16,
                        child: IconButton(
                          icon: const Icon(Icons.delete,
                              size: 16, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              switch (imageType) {
                                case 1:
                                  _frontViewImage = null;
                                  break;
                                case 2:
                                  _lowerDieImage = null;
                                  break;
                                case 3:
                                  _upperDieImage = null;
                                  break;
                                case 4:
                                  _partProsesImage = null;
                                  break;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        _showImageSourceOptions(context, imageType),
                    child: Text('Upload $title'),
                  ),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveToolingData() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading dialog instead of SnackBar, matching the trial form
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Saving data, please wait...")
                  ],
                ),
              ),
            );
          },
        );

        final user = FirebaseAuth.instance.currentUser;
        // Extract username from email
        String userEmail = user?.email ?? 'unknown@example.com';
        String username = userEmail.split('@')[0];

        // Create data object without media first
        final data = {
          'kapasitas': _capacityController.text,
          'mc_name': _mcNameController.text,
          'nama_part': _namaPartController.text,
          'panjang': _panjangController.text,
          'lebar': _lebarController.text,
          'tinggi': _tinggiController.text,
          'user': userEmail,
          'display_name': username,
          // Image fields will be added later if upload succeeds
        };

        // Try to upload media files but catch errors
        try {
          // First upload media files to Google Drive
          final mediaUrls = await ToolingModel.uploadMediaFiles(
            imgFrontView: _frontViewImage,
            imgLowerDie: _lowerDieImage,
            imgUpperDie: _upperDieImage,
            imgPartProses: _partProsesImage,
          );

          // Add media URLs to data if upload succeeded
          if (mediaUrls.containsKey('imgFrontView')) {
            data['img_fv'] = mediaUrls['imgFrontView'] ?? '';
          }
          if (mediaUrls.containsKey('imgLowerDie')) {
            data['img_ldv'] = mediaUrls['imgLowerDie'] ?? '';
          }
          if (mediaUrls.containsKey('imgUpperDie')) {
            data['img_udv'] = mediaUrls['imgUpperDie'] ?? '';
          }
          if (mediaUrls.containsKey('imgPartProses')) {
            data['img_part'] = mediaUrls['imgPartProses'] ?? '';
          }
        } catch (uploadError) {
          print("Upload error: $uploadError"); // Debug print

          // If we're editing, keep the existing image URLs
          if (_isEditing && _docId != null) {
            try {
              DocumentSnapshot doc = await FirebaseFirestore.instance
                  .collection('Tooling')
                  .doc(_docId)
                  .get();

              if (doc.exists) {
                Map<String, dynamic> existingData =
                    doc.data() as Map<String, dynamic>;
                // Use safe field names
                data['img_fv'] = existingData['img_fv'] ?? '';
                data['img_ldv'] = existingData['img_ldv'] ?? '';
                data['img_udv'] = existingData['img_udv'] ?? '';
                data['img_part'] = existingData['img_part'] ?? '';
              }
            } catch (e) {
              print('Error retrieving existing image URLs: $e');
            }
          }
        }

        // Hide loading dialog
        Navigator.pop(context);

        if (_isEditing && _docId != null) {
          // Update existing document
          await FirebaseFirestore.instance
              .collection('Tooling')
              .doc(_docId)
              .update({
            ...data,
            'updated_at': FieldValue.serverTimestamp(),
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tooling data updated successfully')),
          );
        } else {
          // Add creation timestamp for new documents
          await FirebaseFirestore.instance.collection('Tooling').add({
            ...data,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tooling data saved successfully')),
          );
        }

        Navigator.of(context).pop(); // Return to the previous page
      } catch (e) {
        // Hide loading dialog if still showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        print("Error saving tooling data: $e"); // Log error for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to ${_isEditing ? 'update' : 'save'} data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tooling Album' : 'New Tooling Album'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tooling Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Add Nama Part field at the top
              const Text('Nama Part',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _namaPartController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama part',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Text fields
              const Text('Kapasitas',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan kapasitas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mohon masukkan kapasitas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              const Text('M/C Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _mcNameController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama mesin',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mohon masukkan nama mesin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              const Text('Panjang',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _panjangController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan panjang',
                  border: OutlineInputBorder(),
                  suffixText: 'mm',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mohon masukkan panjang';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              const Text('Lebar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _lebarController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan lebar',
                  border: OutlineInputBorder(),
                  suffixText: 'mm',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mohon masukkan lebar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              const Text('Tinggi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _tinggiController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan tinggi',
                  border: OutlineInputBorder(),
                  suffixText: 'mm',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mohon masukkan tinggi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Image Upload Sections
              _buildImageUploadSection('Front View', _frontViewImage, 1),
              _buildImageUploadSection('Lower Die', _lowerDieImage, 2),
              _buildImageUploadSection('Upper Die', _upperDieImage, 3),
              _buildImageUploadSection('Part Proses', _partProsesImage, 4),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveToolingData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      _isEditing ? 'Update' : 'Submit',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class TrialDetailPage extends StatefulWidget {
  final TrialModel trial;

  const TrialDetailPage({Key? key, required this.trial}) : super(key: key);

  @override
  State<TrialDetailPage> createState() => _TrialDetailPageState();
}

class _TrialDetailPageState extends State<TrialDetailPage> {
  String? currentStatus;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the latest status from Firebase when the page loads
    _fetchCurrentStatus();
  }

  // Fetch the current status from Firestore
  Future<void> _fetchCurrentStatus() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Trial')
          .doc(widget.trial.id)
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          currentStatus = data['status'] ?? 'open';
          isLoading = false;
        });
      } else {
        // If document doesn't exist, fall back to the model's status
        setState(() {
          currentStatus = widget.trial.status ?? 'open';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching status: $e');
      // Fall back to the model's status in case of error
      setState(() {
        currentStatus = widget.trial.status ?? 'open';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trial.namaPart),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            if (widget.trial.imagePath.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: DriveImageView(
                  url: widget.trial.imagePath,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Trial Information Box
                  _buildSectionBox(
                    'Trial Information',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show status as a read-only detail row
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  'Status:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text(
                                        currentStatus == 'close'
                                            ? 'Closed'
                                            : 'Open',
                                        style: TextStyle(
                                          color: currentStatus == 'close'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        _buildDetailRow('Customer', widget.trial.namaCustomer),
                        _buildDetailRow('Part Name', widget.trial.namaPart),
                        _buildDetailRow('Part No', widget.trial.noPart),
                        _buildDetailRow('Process', widget.trial.proses),
                        _buildDetailRow('Project No', widget.trial.noProject),
                        _buildDetailRow('Material Spec', widget.trial.matSpec),
                        _buildDetailRow('Material Size', widget.trial.matSize),
                        _buildDetailRow('M/C Name', widget.trial.mcName),
                        _buildDetailRow(
                            'M/C Capacity', widget.trial.mcCapacity),
                        _buildDetailRow('DH Height', widget.trial.dhHeight),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Problem Tools Box
                  _buildSectionBox(
                    'Problem Tools (Dies Machine)',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Problem', widget.trial.problemTool),
                        _buildDetailRow(
                            'Analisa Penyebab', widget.trial.analisaTool),
                        _buildDetailRow(
                            'Counter Measure', widget.trial.counterTool),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Problem Part Box
                  _buildSectionBox(
                    'Problem Part (Hasil Part)',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Problem', widget.trial.problemPart),
                        _buildDetailRow(
                            'Analisa Penyebab', widget.trial.analisaPart),
                        _buildDetailRow(
                            'Counter Measure', widget.trial.counterPart),
                      ],
                    ),
                  ),

                  // Video section if available
                  if (widget.trial.videoPath.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionBox(
                      'Video Documentation',
                      DriveVideoView(
                        url: widget.trial.videoPath,
                        showControls: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBox(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'N/A'),
          ),
        ],
      ),
    );
  }
}

class ToolingDetailPage extends StatefulWidget {
  final ToolingModel tooling;

  const ToolingDetailPage({Key? key, required this.tooling}) : super(key: key);

  @override
  State<ToolingDetailPage> createState() => _ToolingDetailPageState();
}

class _ToolingDetailPageState extends State<ToolingDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tooling.namaPart.isNotEmpty
            ? widget.tooling.namaPart
            : widget.tooling.mcName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main image (Front View)
            if (widget.tooling.imgFrontView.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: DriveImageView(
                  url: widget.tooling.imgFrontView,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tooling Information Box
                  _buildSectionBox(
                    'Tooling Information',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Nama Part', widget.tooling.namaPart),
                        _buildDetailRow('M/C Name', widget.tooling.mcName),
                        _buildDetailRow('Kapasitas', widget.tooling.kapasitas),
                        _buildDetailRow(
                            'Panjang', '${widget.tooling.panjang} mm'),
                        _buildDetailRow('Lebar', '${widget.tooling.lebar} mm'),
                        _buildDetailRow(
                            'Tinggi', '${widget.tooling.tinggi} mm'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lower Die Image Box
                  if (widget.tooling.imgLowerDie.isNotEmpty)
                    _buildSectionBox(
                      'Lower Die',
                      DriveImageView(
                        url: widget.tooling.imgLowerDie,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),

                  if (widget.tooling.imgLowerDie.isNotEmpty)
                    const SizedBox(height: 16),

                  // Upper Die Image Box
                  if (widget.tooling.imgUpperDie.isNotEmpty)
                    _buildSectionBox(
                      'Upper Die',
                      DriveImageView(
                        url: widget.tooling.imgUpperDie,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),

                  if (widget.tooling.imgUpperDie.isNotEmpty)
                    const SizedBox(height: 16),

                  // Part Process Image Box
                  if (widget.tooling.imgPartProses.isNotEmpty)
                    _buildSectionBox(
                      'Part Process',
                      DriveImageView(
                        url: widget.tooling.imgPartProses,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBox(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'N/A'),
          ),
        ],
      ),
    );
  }
}
