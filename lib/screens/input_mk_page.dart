import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
import '../models/data_manager.dart';

class InputMKPage extends StatefulWidget {
  const InputMKPage({super.key});

  @override
  _InputMKPageState createState() => _InputMKPageState();
}

class _InputMKPageState extends State<InputMKPage> {
  final TextEditingController _mkController = TextEditingController();
  List<MataKuliah> _mataKuliah = [];
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
      final response = await http.get(Uri.parse('https://ahmad2711.rf.gd/api/mk.php?user_id=$_userId'));
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _mataKuliah = (data['mata_kuliah'] as List).map((e) => MataKuliah.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    await DataManager.saveMataKuliah(_mataKuliah);
  }

  void _addMK() async {
    if (_mkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama mata kuliah tidak boleh kosong')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak terdeteksi')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://ahmad2711.rf.gd/api/mk.php?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nama': _mkController.text}),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        _mkController.clear();
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mata kuliah berhasil ditambahkan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _editMK(int index) {
    _mkController.text = _mataKuliah[index].nama;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Mata Kuliah'),
        content: TextField(
          controller: _mkController,
          decoration: InputDecoration(
            labelText: 'Nama Mata Kuliah',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _mkController.clear();
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mataKuliah[index] = MataKuliah(nama: _mkController.text);
              });
              _saveData();
              Navigator.of(context).pop();
              _mkController.clear();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteMK(int index) async {
    final mk = _mataKuliah[index];
    if (mk.id != null && _userId != null) {
      try {
        final response = await http.delete(Uri.parse('https://ahmad2711.rf.gd/api/mk.php?user_id=$_userId&id=${mk.id}'));
        final data = jsonDecode(response.body);
        if (data['success']) {
          _loadData();
        }
      } catch (e) {
        debugPrint('Error deleting MK: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Input Mata Kuliah'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Header dengan gradient
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kelola Mata Kuliah',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambahkan dan kelola semua mata kuliah Anda',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Input Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tambah Mata Kuliah Baru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _mkController,
                            decoration: InputDecoration(
                              hintText: 'Nama Mata Kuliah',
                              prefixIcon: const Icon(Icons.book_rounded, color: Color(0xFF6366F1)),
                              filled: true,
                              fillColor: const Color(0xFFF5F7FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addMK,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tambah Mata Kuliah'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // List Section
                    if (_mataKuliah.isNotEmpty) ...[  
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Daftar Mata Kuliah (${_mataKuliah.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _mataKuliah.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.1),
                                  const Color(0xFF8B5CF6).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.book_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _mataKuliah[index].nama,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      color: Colors.orange,
                                      onPressed: () => _editMK(index),
                                      splashRadius: 24,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded),
                                      color: Colors.red,
                                      onPressed: () => _deleteMK(index),
                                      splashRadius: 24,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada mata kuliah',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
