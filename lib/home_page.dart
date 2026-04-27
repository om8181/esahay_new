import 'package:e_sahay_new/document_wallet_page.dart';
import 'package:flutter/material.dart';
import 'eligibility_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const GovernmentSchemeSections(),
    const ApplicationsPage(),
    const DocumentWalletPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text("Gov-Connect"),
      ),

      body: Column(
        children: [
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Search schemes",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _pages[_currentIndex],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Applications"),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ================= HOME SECTION =================

class GovernmentSchemeSections extends StatefulWidget {
  const GovernmentSchemeSections({super.key});

  @override
  State<GovernmentSchemeSections> createState() =>
      _GovernmentSchemeSectionsState();
}

class _GovernmentSchemeSectionsState extends State<GovernmentSchemeSections> {

  final PageController _controller = PageController();
  int _currentPage = 0;

  // 🔥 IMAGE MAPPING
  String getSchemeImage(String title) {
    if (title == "EBC Scholarship") {
      return "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w400";
    } else if (title == "PM Kisan Samman Nidhi") {
      return "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w400";
    } else if (title == "Ayushman Bharat") {
      return "https://images.unsplash.com/photo-1580281657521-7f1c1b5f8c3b?w400";
    } else {
      return "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w400";
    }
  }
//ignore: unused_element
  Future<Map<String, dynamic>?> _getUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  // 🔥 FIXED FAST + SAFE RECOMMENDATION
  Future<List<Map<String, dynamic>>> _getRecommendedSchemes() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 🔥 fetch user
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final user = userDoc.data();
    if (user == null) return [];

    // 🔥 fetch schemes (limited)
    final snapshot = await FirebaseFirestore.instance
        .collection('schemes')
        .limit(10)
        .get();

    List<Map<String, dynamic>> result = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      int score = 0;

      if (data['category'] == user['category']) score += 30;

      if (data['maxIncome'] != null &&
          user['income'] != null &&
          user['income'] <= data['maxIncome']) score += 25;

      if (data['type'] == "State" &&
          data['state'] == user['state']) score += 20;

      if (data['isStudent'] == true &&
          user['isStudent'] == true) score += 15;

      if (score > 0) result.add(data);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getRecommendedSchemes(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final schemes = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text("Recommended for You",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              if (schemes.isNotEmpty)
                Column(
                  children: [

                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: schemes.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          final scheme = schemes[index];

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                )
                              ],
                              image: DecorationImage(
                                image: ResizeImage(
                                  NetworkImage(getSchemeImage(scheme['title'] ?? "")),
                                  width: 400, // 🔥 makes image lighter
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    scheme['title'] ?? "Scheme",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    scheme['category'] ?? "",
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        schemes.length,
                            (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == index ? 10 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.blue
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              const Text("Central Government Schemes",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              _categoryGrid(context, "Central"),

              const SizedBox(height: 20),

              const Text("State Government Schemes",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              _categoryGrid(context, "State"),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryGrid(BuildContext context, String type) {
    final categories = [
      {"label": "Education", "icon": Icons.school, "color": Colors.blue},
      {"label": "Health", "icon": Icons.local_hospital, "color": Colors.red},
      {"label": "Agriculture", "icon": Icons.agriculture, "color": Colors.green},
      {"label": "Women", "icon": Icons.woman, "color": Colors.pink},
      {"label": "Employment", "icon": Icons.work, "color": Colors.orange},
      {"label": "Housing", "icon": Icons.home, "color": Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EligibilityPage(
                  category: category["label"] as String,
                  type: type,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: (category["color"] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category["icon"] as IconData,
                    color: category["color"] as Color),
                const SizedBox(height: 6),
                Text(
                  category["label"] as String,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= APPLICATIONS =================

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  final TextEditingController controller = TextEditingController();

  String? status;

  // 🔥 history list (no database)
  List<Map<String, String>> history = [];

  // 🔥 Generate status from ID
  String getStatusFromId(String id) {
    if (id.isEmpty) return "Invalid";

    int lastDigit = int.tryParse(id[id.length - 1]) ?? 0;

    if (lastDigit <= 2) return "Pending";
    if (lastDigit <= 5) return "Approved";
    return "Rejected";
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case "Approved":
        return Icons.check_circle;
      case "Pending":
        return Icons.access_time;
      case "Rejected":
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void checkStatus() {
    final id = controller.text.trim();
    if (id.isEmpty) return;

    final resultStatus = getStatusFromId(id);

    setState(() {
      status = resultStatus;

      history.insert(0, {
        "id": id,
        "status": resultStatus,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔵 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Track Application",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Enter your Application ID",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 INPUT CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Enter Application ID",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: checkStatus,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Track Now",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 RESULT CARD
            if (status != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      getStatusColor(status!).withOpacity(0.8),
                      getStatusColor(status!).withOpacity(0.5),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      getStatusIcon(status!),
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PM Kisan Samman Nidhi",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Application ID: ${controller.text}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      status!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),

            // 🔹 HISTORY TITLE
            if (history.isNotEmpty)
              const Text(
                "Previous Searches",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

            const SizedBox(height: 10),

            // 🔹 HISTORY LIST
            if (history.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          getStatusIcon(item["status"]!),
                          color: getStatusColor(item["status"]!),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item["id"]!),
                        ),
                        Text(
                          item["status"]!,
                          style: TextStyle(
                            color: getStatusColor(item["status"]!),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ================= PROFILE =================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();

  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Text(
                  user['name'][0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 28, color: Colors.white),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                user['name'],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Text(user['email']),

              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text("Category"),
                  subtitle: Text(user['category'] ?? ""),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: const Text("Income"),
                  subtitle: Text(user['income'].toString()),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              )
            ],
          ),
        );
      },
    );
  }
}