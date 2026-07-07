import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late Profil _profil;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _jurusanController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();

  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    if (_userId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    try {
      final response = await http.get(Uri.parse('http://localhost/api/profil.php?user_id=$_userId'));
      final data = jsonDecode(response.body);
      if (data['success']) {
        final p = data['profil'];
        setState(() {
          _profil = Profil.fromJson(p);
          _namaController.text = _profil.nama;
          _nimController.text = _profil.nim;
          _jurusanController.text = _profil.jurusan;
          _semesterController.text = _profil.semester;
        });
      } else {
        // Default profil
        _profil = Profil(nama: 'Nama', nim: 'NIM', jurusan: 'Jurusan', semester: 'Semester');
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveData() async {
    if (_userId == null) return;
    try {
      final response = await http.post(
        Uri.parse('http://localhost/api/profil.php?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': _namaController.text,
          'nim': _nimController.text,
          'jurusan': _jurusanController.text,
          'semester': _semesterController.text,
        }),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal menyimpan: ${data['message']}')),
        );
        debugPrint('Error: ${data['message']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error koneksi: $e')),
      );
      debugPrint('Exception: $e');
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF7494EC)),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveData,
          )
        ],
      ),
      backgroundColor: const Color(0xFFADD8E6),
      body: Container(
        width: double.infinity,
        color: const Color(0xFFADD8E6),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 55,
                backgroundColor: Color(0xFF7494EC),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 6,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _namaController,
                        decoration:
                            _inputDecoration('Nama', Icons.person),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _nimController,
                        decoration:
                            _inputDecoration('NIM', Icons.badge),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _jurusanController,
                        decoration:
                            _inputDecoration('Jurusan', Icons.school),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _semesterController,
                        decoration: _inputDecoration(
                            'Semester', Icons.calendar_today),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveData,
                          icon: const Icon(Icons.save),
                          label: const Text("Simpan Profil"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFF7494EC),
                          ),
                        ),
                      ),
                    ],
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