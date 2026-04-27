import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scheme_list_page.dart';

class EligibilityPage extends StatefulWidget {
  final String category;
  final String type;
  final String? state;

  const EligibilityPage({
    super.key,
    required this.category,
    required this.type,
    this.state,
  });

  @override
  State<EligibilityPage> createState() => _EligibilityPageState();
}

class _EligibilityPageState extends State<EligibilityPage> {
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> answers = {};

  int currentIndex = 0;
  bool isLoading = true;

  final TextEditingController _controller = TextEditingController();
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.category.toLowerCase())
          .collection(widget.type)
          .doc("data")
          .collection('questions')
          .get();

      final fetchedQuestions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "q": data["label"] ?? "",
          "key": data["id"] ?? "",
          "type": (data["type"] ?? "").toString().toLowerCase(),
          "options": data["options"] ?? [],
        };
      }).toList();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      print("🔥 FIREBASE ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  void next(dynamic value) {
    answers[questions[currentIndex]["key"]] = value;

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        _controller.clear();
        selectedValue = null;
      });
    } else {
      showEligibleSchemes();
    }
  }

  Future<List<Map<String, dynamic>>> getEligibleSchemes() async {
    Query query = FirebaseFirestore.instance
        .collection('schemes')
        .where("category", isEqualTo: widget.category)
        .where("type", isEqualTo: widget.type);

    if (widget.type == "State") {
      final selectedState = answers["state"] ?? widget.state;
      if (selectedState != null) {
        query = query.where("state", isEqualTo: selectedState);
      }
    }

    final snapshot = await query.get();

    List<Map<String, dynamic>> result = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final conditions = data["conditions"] ?? {};

      bool eligible = true;

      for (var key in conditions.keys) {
        if (!answers.containsKey(key)) continue;

        final condition = conditions[key];
        final userValue = answers[key];

        if (condition is num) {
          final userNum = num.tryParse(userValue.toString());
          if (userNum == null || userNum > condition) {
            eligible = false;
            break;
          }
        } else if (condition is bool) {
          if (userValue != condition) {
            eligible = false;
            break;
          }
        } else {
          if (userValue.toString().toLowerCase() !=
              condition.toString().toLowerCase()) {
            eligible = false;
            break;
          }
        }
      }

      if (eligible) result.add(data);
    }

    return result;
  }

  void showEligibleSchemes() async {
    final schemes = await getEligibleSchemes();

    if (schemes.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("No Schemes ❌"),
          content: Text("You are not eligible"),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchemeListPage(schemes: schemes),
      ),
    );
  }

  bool isInputValid(Map<String, dynamic> q) {
    if (q["type"] == "number") {
      return _controller.text.isNotEmpty;
    } else if (q["type"] == "dropdown" || q["type"] == "array") {
      return selectedValue != null;
    }
    return true;
  }

  Widget buildOptionButton(String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: const Center(child: Text("No questions found")),
      );
    }

    final q = questions[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // 🔷 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${widget.type} Eligibility Check",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: (currentIndex + 1) / questions.length,
                  backgroundColor: Colors.white24,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🔶 QUESTION CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.smart_toy,
                        size: 40, color: Colors.blue),
                    const SizedBox(height: 10),
                    Text(
                      q["q"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // 🔽 INPUT AREA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (q["type"] == "bool") ...[
                    buildOptionButton("Yes", () => next(true)),
                    buildOptionButton("No", () => next(false)),
                  ],

                  if (q["type"] == "number") ...[
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter value",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  if ((q["type"] == "dropdown" || q["type"] == "array") &&
                      (q["options"] as List).isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedValue,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      hint: const Text("Select option"),
                      items: (q["options"] as List)
                          .map<DropdownMenuItem<String>>((e) {
                        return DropdownMenuItem(
                          value: e.toString(),
                          child: Text(e.toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedValue = val);
                      },
                    ),
                  ],

                  const Spacer(),

                  // 🔘 CTA BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isInputValid(q)
                          ? () {
                        if (q["type"] == "number") {
                          final value =
                              int.tryParse(_controller.text) ?? 0;
                          next(value);
                        } else if (q["type"] == "dropdown" ||
                            q["type"] == "array") {
                          next(selectedValue);
                        }
                      }
                          : null,
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 18,),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}