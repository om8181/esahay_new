import 'package:flutter/material.dart';
import 'package:e_sahay_new/scheme_detail_page.dart';

class SchemeListPage extends StatelessWidget {
  final List<Map<String, dynamic>> schemes;

  const SchemeListPage({
    super.key,
    required this.schemes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Eligible Schemes"),
        backgroundColor: Colors.blue,
      ),

      body: schemes.isEmpty
          ? const Center(child: Text("No schemes available"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: schemes.length,
        itemBuilder: (context, index) {
          final scheme = schemes[index];

          final String name =
          (scheme["title"] ?? "No Name").toString();

          final String description =
          (scheme["description"] ??
              "No description available")
              .toString();

          final String typeText =
          (scheme["type"] ?? "").toString();

          return Card(
            elevation: 3,
            margin:
            const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SchemeDetailPage(
                          scheme: scheme,
                        ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    // 🔵 ICON
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 📄 TEXT
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          // 🔥 NAME
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // 🔹 DESCRIPTION
                          Text(
                            description,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                              Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 🔹 TYPE CHIP
                          if (typeText.isNotEmpty)
                            _chip(typeText),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 CHIP
  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}