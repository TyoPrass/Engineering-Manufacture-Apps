import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get total count of Trial documents
  Future<int> getTrialCount() async {
    QuerySnapshot snapshot = await _firestore.collection('Trial').get();
    return snapshot.size;
  }

  // Get total count of Tooling documents
  Future<int> getToolingCount() async {
    QuerySnapshot snapshot = await _firestore.collection('Tooling').get();
    return snapshot.size;
  }

  // Get count of open and closed Trial documents
  Future<Map<String, int>> getTrialStatusCounts() async {
    Map<String, int> counts = {'open': 0, 'close': 0};

    QuerySnapshot snapshot = await _firestore.collection('Trial').get();

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String status = data['status'] ?? 'open';
      counts[status.toLowerCase()] = (counts[status.toLowerCase()] ?? 0) + 1;
    }

    return counts;
  }

  // Get monthly Trial and Tooling counts for the current year
  Future<Map<String, List<int>>> getMonthlyDataCounts() async {
    Map<String, List<int>> result = {
      'months': List.generate(12, (index) => index + 1),
      'trialCounts': List.filled(12, 0),
      'toolingCounts': List.filled(12, 0),
    };

    // Get current year
    int currentYear = DateTime.now().year;

    // Get start and end timestamps for the year
    DateTime startOfYear = DateTime(currentYear, 1, 1);
    DateTime endOfYear = DateTime(currentYear + 1, 1, 1);

    // Query trials
    QuerySnapshot trialSnapshot = await _firestore
        .collection('Trial')
        .where('created_at', isGreaterThanOrEqualTo: startOfYear)
        .where('created_at', isLessThan: endOfYear)
        .get();

    // Query tooling
    QuerySnapshot toolingSnapshot = await _firestore
        .collection('Tooling')
        .where('created_at', isGreaterThanOrEqualTo: startOfYear)
        .where('created_at', isLessThan: endOfYear)
        .get();

    // Process trial data
    for (var doc in trialSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['created_at'] as Timestamp?;

      if (timestamp != null) {
        DateTime date = timestamp.toDate();
        int month = date.month;
        result['trialCounts']![month - 1]++;
      }
    }

    // Process tooling data
    for (var doc in toolingSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['created_at'] as Timestamp?;

      if (timestamp != null) {
        DateTime date = timestamp.toDate();
        int month = date.month;
        result['toolingCounts']![month - 1]++;
      }
    }

    return result;
  }

  // Get team members count (users who have submitted data)
  Future<int> getTeamMembersCount() async {
    QuerySnapshot trialSnapshot = await _firestore.collection('Trial').get();
    QuerySnapshot toolingSnapshot =
        await _firestore.collection('Tooling').get();

    Set<String> uniqueUsers = {};

    for (var doc in trialSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String user = data['user'] ?? '';
      if (user.isNotEmpty) {
        uniqueUsers.add(user);
      }
    }

    for (var doc in toolingSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String user = data['user'] ?? '';
      if (user.isNotEmpty) {
        uniqueUsers.add(user);
      }
    }

    return uniqueUsers.length;
  }

  // Calculate completion percentage
  Future<double> getCompletionPercentage() async {
    Map<String, int> trialStatus = await getTrialStatusCounts();
    int closedTrials = trialStatus['close'] ?? 0;
    int totalTrials = (trialStatus['open'] ?? 0) + closedTrials;

    if (totalTrials == 0) return 0.0;
    return (closedTrials / totalTrials) * 100;
  }
}
