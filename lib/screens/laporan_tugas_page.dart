import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
import '../models/data_manager.dart';

class LaporanTugasPage extends StatefulWidget {
  const LaporanTugasPage({super.key});

  @override
  _LaporanTugasPageState createState() => _LaporanTugasPageState();
}

class _LaporanTugasPageState extends State<LaporanTugasPage> {
  List<Tugas> _tugas = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    
    try {
      final response = await http.get(Uri.parse('http://localhost/api/tugas.php?user_id=$_userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _tugas = (data['tugas'] as List).map((e) => Tugas.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading tugas: $e');
    }
  }

  Future<void> _toggleSelesai(int index) async {
    final tugasId = _tugas[index].id;
    if (tugasId == null || _userId == null) return;

    try {
      final response = await http.put(
        Uri.parse('http://localhost/api/tugas.php?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': tugasId,
          'selesai': _tugas[index].selesai ? 0 : 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _tugas[index].selesai = !_tugas[index].selesai;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating tugas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTugas = _tugas.length;
    final selesai = _tugas.where((t) => t.selesai).length;
    final belum = totalTugas - selesai;
    final persentase = totalTugas == 0 ? 0.0 : (selesai / totalTugas) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Laporan Tugas'),
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
                colors: [Color(0xFF0066FF), Color(0xFF00B4D8)],
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
                    Icons.assessment_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Laporan Tugas',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau progres penyelesaian tugas Anda',
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
                    // Statistics Section
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
                        children: [
                          Row(
                            children: [
                              // Total Tasks
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Total Tugas',
                                  value: totalTugas.toString(),
                                  icon: Icons.task_alt_rounded,
                                  color: const Color(0xFF0066FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Completed
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Selesai',
                                  value: selesai.toString(),
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF2ECC71),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Pending
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Belum',
                                  value: belum.toString(),
                                  icon: Icons.hourglass_bottom_rounded,
                                  color: const Color(0xFFFFA500),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Percentage
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Progres',
                                  value: '${persentase.toStringAsFixed(0)}%',
                                  icon: Icons.trending_up_rounded,
                                  color: const Color(0xFF00B4D8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Progress Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0066FF).withOpacity(0.1),
                            const Color(0xFF00B4D8).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00B4D8).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Persentase Penyelesaian',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: persentase / 100,
                              minHeight: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                persentase < 50
                                    ? const Color(0xFFFFA500)
                                    : persentase < 80
                                        ? const Color(0xFF0066FF)
                                        : const Color(0xFF2ECC71),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${persentase.toStringAsFixed(1)}% selesai',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Tugas Belum Selesai
                    if (_tugas.where((t) => !t.selesai).isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tugas Belum Selesai (${belum})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tugas.where((t) => !t.selesai).length,
                        itemBuilder: (context, index) {
                          final tugasBelum = _tugas.where((t) => !t.selesai).toList();
                          final t = tugasBelum[index];
                          final originalIndex = _tugas.indexOf(t);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: const Color(0xFFFFA500),
                                  width: 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleSelesai(originalIndex),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFFFA500),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.deskripsi,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (t.mataKuliah != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'MK: ${t.mataKuliah}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Tugas Selesai
                    if (_tugas.where((t) => t.selesai).isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tugas Selesai (${selesai})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tugas.where((t) => t.selesai).length,
                        itemBuilder: (context, index) {
                          final tugasSelesai = _tugas.where((t) => t.selesai).toList();
                          final t = tugasSelesai[index];
                          final originalIndex = _tugas.indexOf(t);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: Colors.teal,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleSelesai(originalIndex),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.deskripsi,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[500],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      if (t.mataKuliah != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'MK: ${t.mataKuliah}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    if (_tugas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assessment_rounded,
                              size: 64,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada tugas',
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
