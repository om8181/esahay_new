import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeDetailPage extends StatefulWidget {
  final Map<String, dynamic> scheme;

  const SchemeDetailPage({
    super.key,
    required this.scheme,
  });

  @override
  State<SchemeDetailPage> createState() => _SchemeDetailPageState();
}

class _SchemeDetailPageState extends State<SchemeDetailPage> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();

    final videoUrl = widget.scheme["videoUrl"];

    if (videoUrl != null && videoUrl.toString().isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);

      if (videoId != null) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;

    final name = scheme["title"] ?? "No Name";
    final description =
        scheme["description"] ?? "No description available";
    final type = scheme["type"] ?? "";

    // 🔥 FIXED DOCUMENT HANDLING
    final rawDocs = scheme["documents"] ?? scheme["Documents"];

    List<String> documents = [];

    if (rawDocs is List) {
      documents = List<String>.from(rawDocs);
    } else if (rawDocs is String && rawDocs.isNotEmpty) {
      documents = [rawDocs];
    }

    final applyLink = scheme["applyLink"];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue,
      ),

      // 🔥 APPLY BUTTON (BOTTOM)
      bottomNavigationBar: (applyLink != null &&
          applyLink.toString().isNotEmpty)
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openLink(applyLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                    vertical: 14),
              ),
              child: const Text("Apply Now"),
            ),
          ),
        ),
      )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 TITLE
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // 🔹 TYPE CHIP
            if (type.isNotEmpty) _chip(type),

            const SizedBox(height: 12),

            // 🔹 DESCRIPTION
            Text(
              description,
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),

            // 🎥 VIDEO
            if (_controller != null) ...[
              const Text(
                "How to Apply",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              YoutubePlayer(controller: _controller!),
              const SizedBox(height: 20),
            ],

            // 📄 DOCUMENTS
            if (documents.isNotEmpty) ...[
              const Text(
                "Required Documents",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: documents.map((doc) {
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(doc)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}