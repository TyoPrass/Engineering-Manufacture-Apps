import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engginering/services/bookmark_service.dart';
import 'package:engginering/models/trial_model.dart';
import 'package:engginering/models/tooling_model.dart';
import 'package:engginering/pages/details_page.dart';
import 'package:engginering/widgets/drive_image_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
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
                          'Saved Trials',
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
                          'Saved Toolings',
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildLoginRequiredView();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: StreamBuilder<List<String>>(
        stream: _bookmarkService.getBookmarkedIds('Trial'),
        builder: (context, bookmarkSnapshot) {
          if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookmarkSnapshot.hasError) {
            return _buildErrorView(bookmarkSnapshot.error.toString());
          }

          List<String> bookmarkedIds = bookmarkSnapshot.data ?? [];

          if (bookmarkedIds.isEmpty) {
            return _buildEmptyBookmarksView('trials');
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Trial')
                .where(FieldPath.documentId, whereIn: bookmarkedIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorView(snapshot.error.toString());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyBookmarksView('trials');
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
                    return _buildSavedTrialCard(trial);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSavedTrialCard(TrialModel trial) {
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
          ).then((_) => setState(() {}));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with menu button overlay
            Stack(
              children: [
                // Image container
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.grey),
                    child: DriveImageView(
                      url: trial.imagePath,
                      fit: BoxFit.cover,
                    ),
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
                  Text(
                    trial.namaPart,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No. ${trial.noPart}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${trial.namaCustomer}',
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
                  // Add remove bookmark button
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () async {
                          await _bookmarkService.removeBookmark(
                              'Trial', trial.id);
                          setState(() {});
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.bookmark_remove,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.red,
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
      ),
    );
  }

  Widget _buildToolingView() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildLoginRequiredView();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: StreamBuilder<List<String>>(
        stream: _bookmarkService.getBookmarkedIds('Tooling'),
        builder: (context, bookmarkSnapshot) {
          if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookmarkSnapshot.hasError) {
            return _buildErrorView(bookmarkSnapshot.error.toString());
          }

          List<String> bookmarkedIds = bookmarkSnapshot.data ?? [];

          if (bookmarkedIds.isEmpty) {
            return _buildEmptyBookmarksView('toolings');
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Tooling')
                .where(FieldPath.documentId, whereIn: bookmarkedIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorView(snapshot.error.toString());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyBookmarksView('toolings');
              }

              // Convert Firestore documents to ToolingModel objects
              List<ToolingModel> toolings = snapshot.data!.docs.map((doc) {
                return ToolingModel.fromFirestore(doc);
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: toolings.length,
                  itemBuilder: (context, index) {
                    ToolingModel tooling = toolings[index];
                    return _buildSavedToolingCard(tooling);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSavedToolingCard(ToolingModel tooling) {
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
          ).then((_) => setState(() {}));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with remove bookmark button
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.grey),
                    child: DriveImageView(
                      url: tooling.imgFrontView,
                      fit: BoxFit.cover,
                    ),
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
                  Text(
                    tooling.mcName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  // Add remove bookmark button
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () async {
                          await _bookmarkService.removeBookmark(
                              'Tooling', tooling.id);
                          setState(() {});
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.bookmark_remove,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.red,
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
      ),
    );
  }

  // Helper method for building error view
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading saved items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Retry loading data
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper method for empty bookmarks view
  Widget _buildEmptyBookmarksView(String itemType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bookmark_border,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved $itemType',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bookmark $itemType you want to save for later',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to show login required message
  Widget _buildLoginRequiredView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Login Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'You need to be logged in to view your saved items.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
              Navigator.of(context).pushNamed('/login');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
