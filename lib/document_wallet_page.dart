import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

// 🔐 Encryption + Firebase
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void _openFile(PlatformFile file) {
  if (file.path != null) {
    OpenFilex.open(file.path!);
  }
}

class DocumentWalletPage extends StatefulWidget {
  const DocumentWalletPage({super.key});

  @override
  State<DocumentWalletPage> createState() => _DocumentWalletPageState();
}

class _DocumentWalletPageState extends State<DocumentWalletPage> {

  final List<Map<String, dynamic>> documentTypes = [
    {"name": "Aadhaar Card", "icon": Icons.credit_card, "color": Colors.blue},
    {"name": "PAN Card", "icon": Icons.badge, "color": Colors.deepPurple},
    {"name": "Income Certificate", "icon": Icons.description, "color": Colors.green},
    {"name": "Caste Certificate", "icon": Icons.assignment, "color": Colors.orange},
    {"name": "Domicile Certificate", "icon": Icons.home, "color": Colors.teal},
    {"name": "Bank Passbook", "icon": Icons.account_balance, "color": Colors.indigo},
  ];

  Map<String, PlatformFile?> uploadedDocs = {};

  final _secureStorage = const FlutterSecureStorage();

  // 🔑 KEY MANAGEMENT
  Future<encrypt.Key> getUserKey(String userId) async {
    String? keyString = await _secureStorage.read(key: "key_$userId");

    if (keyString == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: "key_$userId",
        value: key.base64,
      );
      return key;
    }

    return encrypt.Key.fromBase64(keyString);
  }

  // 📂 PICK FILE
  Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  // 🔒 ENCRYPT FILE
  Future<File> encryptFile(File file, encrypt.Key key) async {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final bytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final combined = iv.bytes + encrypted.bytes;

    final encryptedFile = File("${file.path}.enc");
    await encryptedFile.writeAsBytes(combined);

    return encryptedFile;
  }

  // ☁️ UPLOAD
  Future<String> uploadFile(File file, String userId) async {
    final ref = FirebaseStorage.instance
        .ref("docs/$userId/${DateTime.now().millisecondsSinceEpoch}.enc");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 🗄️ SAVE DATA
  Future<void> saveDoc(String userId, String docName, String url) async {
    await FirebaseFirestore.instance.collection("documents").add({
      "userId": userId,
      "docName": docName,
      "url": url,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // 🚀 UPLOAD FLOW
  Future<void> _uploadDocument(String docName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    File? file = await pickFile();
    if (file == null) return;

    final key = await getUserKey(userId);

    final encryptedFile = await encryptFile(file, key);

    final url = await uploadFile(encryptedFile, userId);

    await saveDoc(userId, docName, url);

    setState(() {
      uploadedDocs[docName] = PlatformFile(
        name: file.path.split('/').last,
        path: file.path,
        size: file.lengthSync(), // ✅ FIXED ERROR
      );
    });
  }

  void _removeDocument(String docName) {
    setState(() {
      uploadedDocs.remove(docName);
    });
  }

  @override
  Widget build(BuildContext context) {

    int uploadedCount = uploadedDocs.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Document Wallet"),
        centerTitle: true,
        elevation: 0,
      ),

      body: Column(
        children: [

          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Documents",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$uploadedCount / ${documentTypes.length} Uploaded",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: documentTypes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final doc = documentTypes[index];
                final docName = doc["name"];
                final icon = doc["icon"];
                final color = doc["color"];
                final file = uploadedDocs[docName];

                return GestureDetector(
                  onTap: () {
                    if (file != null) {
                      _openFile(file);
                    } else {
                      _uploadDocument(docName);
                    }
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: file != null
                            ? [color.withOpacity(0.8), color]
                            : [Colors.white, Colors.grey.shade200],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(icon,
                                size: 32,
                                color: file != null
                                    ? Colors.white
                                    : color),
                            if (file != null)
                              GestureDetector(
                                onTap: () => _removeDocument(docName),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                          ],
                        ),

                        const Spacer(),

                        Text(
                          docName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: file != null
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              file != null ? "Verified" : "Upload",
                              style: TextStyle(
                                fontSize: 12,
                                color: file != null
                                    ? Colors.white70
                                    : Colors.grey,
                              ),
                            ),
                            Icon(
                              file != null
                                  ? Icons.check_circle
                                  : Icons.upload_file,
                              size: 18,
                              color: file != null
                                  ? Colors.white
                                  : color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}