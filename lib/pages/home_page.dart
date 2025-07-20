import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engginering/controllers/auth_controller.dart';
import 'package:engginering/pages/details_page.dart';
import 'package:engginering/pages/about_page.dart';
import 'package:engginering/pages/edit_profile_page.dart';
import 'package:engginering/pages/about_app_page.dart';
import 'package:engginering/widgets/user_profile_icon.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authController = Get.find<AuthController>();
  int _selectedIndex = 0;

  // Add variables to store counts
  int totalTrials = 0;
  int closedTrials = 0;
  int totalTeamMembers = 0;
  double completionPercentage = 0.0;

  // Add stream subscriptions to listen for data changes
  late StreamSubscription<QuerySnapshot> _trialSubscription;
  late StreamSubscription<QuerySnapshot> _toolingSubscription;
  late StreamSubscription<QuerySnapshot> _usersSubscription;

  // Chart data variables
  DateTime selectedMonth = DateTime.now(); // Current month by default
  List<FlSpot> trialDataPoints = [];
  List<FlSpot> toolingDataPoints = [];
  double maxY = 10; // Default max value for chart Y axis
  int daysInMonth = 30; // Default days in month

  @override
  void initState() {
    super.initState();
    _setupDynamicDataListeners();
    _fetchMonthlyData();

    _pages = [
      Container(), // Placeholder for home view
      const DetailsPage(),
      const AboutPage(),
    ];
  }

  @override
  void dispose() {
    _trialSubscription.cancel();
    _toolingSubscription.cancel();
    _usersSubscription.cancel();
    super.dispose();
  }

  // Method to set up dynamic data listeners
  void _setupDynamicDataListeners() {
    // Listen for changes to Trial collection
    _trialSubscription = FirebaseFirestore.instance
        .collection('Trial')
        .snapshots()
        .listen((snapshot) {
      int trials = snapshot.docs.length;

      // Calculate completion percentage and count closed trials
      int closed = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'close') {
          closed++;
        }
      }

      double percentage = trials > 0 ? (closed / trials) * 100 : 0;

      setState(() {
        totalTrials = trials;
        closedTrials = closed; // Store count of closed trials
        completionPercentage = percentage;
      });
    });

    // Remove the tooling subscription since we're not using it anymore
    _toolingSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      // Just keeping this to avoid breaking the dispose method
    });

    // Listen for changes to users collection
    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        totalTeamMembers = snapshot.docs.length;
      });
    });
  }

  // Fetch data for the selected month
  void _fetchMonthlyData() {
    // Calculate start and end dates for the selected month
    DateTime startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    daysInMonth = endDate.day;

    // Initialize empty data lists
    List<FlSpot> trialSpots =
        List.generate(daysInMonth, (index) => FlSpot(index.toDouble() + 1, 0));
    List<FlSpot> toolingSpots =
        List.generate(daysInMonth, (index) => FlSpot(index.toDouble() + 1, 0));

    // Fetch Trial data
    FirebaseFirestore.instance
        .collection('Trial')
        .where('updated_at', isGreaterThanOrEqualTo: startDate)
        .where('updated_at', isLessThanOrEqualTo: endDate)
        .get()
        .then((querySnapshot) {
      // Count entries per day
      Map<int, int> dailyCounts = {};
      for (var doc in querySnapshot.docs) {
        Timestamp timestamp = doc['updated_at'] as Timestamp;
        DateTime date = timestamp.toDate();
        int day = date.day;
        dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
      }

      // Update spots with actual data
      for (int day = 1; day <= daysInMonth; day++) {
        int count = dailyCounts[day] ?? 0;
        trialSpots[day - 1] = FlSpot(day.toDouble(), count.toDouble());
      }

      setState(() {
        trialDataPoints = trialSpots;
        _updateMaxY();
      });
    });

    // Fetch Tooling data
    FirebaseFirestore.instance
        .collection('Tooling')
        .where('updated_at', isGreaterThanOrEqualTo: startDate)
        .where('updated_at', isLessThanOrEqualTo: endDate)
        .get()
        .then((querySnapshot) {
      // Count entries per day
      Map<int, int> dailyCounts = {};
      for (var doc in querySnapshot.docs) {
        Timestamp timestamp = doc['updated_at'] as Timestamp;
        DateTime date = timestamp.toDate();
        int day = date.day;
        dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
      }

      // Update spots with actual data
      for (int day = 1; day <= daysInMonth; day++) {
        int count = dailyCounts[day] ?? 0;
        toolingSpots[day - 1] = FlSpot(day.toDouble(), count.toDouble());
      }

      setState(() {
        toolingDataPoints = toolingSpots;
        _updateMaxY();
      });
    });
  }

  // Update the max Y value for chart scaling
  void _updateMaxY() {
    double maxTrial = trialDataPoints.isEmpty
        ? 0
        : trialDataPoints.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    double maxTooling = toolingDataPoints.isEmpty
        ? 0
        : toolingDataPoints
            .map((spot) => spot.y)
            .reduce((a, b) => a > b ? a : b);

    double newMaxY = math.max(maxTrial, maxTooling);
    // Set minimum of 5 for better visualization when data is low/empty
    setState(() {
      maxY = math.max(newMaxY + 1, 5);
    });
  }

  // Change month and fetch new data
  void _changeMonth(int delta) {
    setState(() {
      selectedMonth = DateTime(
          selectedMonth.year, selectedMonth.month + delta, selectedMonth.day);
      _fetchMonthlyData();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Add method to handle logout confirmation
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authController.signOut();
              // Navigate to login page after signing out
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // List of pages to display
  late final List<Widget> _pages;

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build the monthly data chart
  Widget _buildMonthlyDataChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('Trial', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem('Tooling', Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 5,
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: daysInMonth <= 15 ? 1 : 5,
                      getTitlesWidget: (value, meta) {
                        if (value % 5 == 0 || daysInMonth <= 15) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${value.toInt()}'),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}');
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // Trial data line
                  LineChartBarData(
                    spots: trialDataPoints,
                    isCurved: false,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  // Tooling data line
                  LineChartBarData(
                    spots: toolingDataPoints,
                    isCurved: false,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engineering App'),
        actions: const [
          UserProfileIcon(),
          SizedBox(width: 8),
        ],
      ),
      drawer: _buildSidebar(),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  const SizedBox(height: 16),
                  GetBuilder<AuthController>(
                    builder: (controller) => Text(
                      'Hello, ${controller.username.value}!',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Text(
                    'Welcome to the Engineering Portal',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Stats cards with real data
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            'Projects',
                            totalTrials.toString(),
                            Icons.assignment,
                            Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                            'Tasks Done',
                            closedTrials.toString(),
                            Icons.task_alt,
                            Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            'Team',
                            totalTeamMembers.toString(),
                            Icons.people,
                            Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                            'Completed',
                            '${completionPercentage.toStringAsFixed(0)}%',
                            Icons.pie_chart,
                            Colors.purple),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Grafik Data Bulanan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // Monthly Data Chart - Add this new section
                  const SizedBox(height: 32),
                  _buildMonthlyDataChart(),
                ],
              ),
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Details',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Saved Data',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ... existing code for _buildActivityItem, _buildQuickAction, and _buildSidebar
  Widget _buildActivityItem(String title, String description, String time,
      IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Text(
          time,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white70,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, ${authController.username.value}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authController.userEmail.value,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
    );
  }
}
