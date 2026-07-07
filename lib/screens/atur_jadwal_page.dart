import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
import '../models/data_manager.dart';

class AturJadwalPage extends StatefulWidget {
  const AturJadwalPage({super.key});

  @override
  _AturJadwalPageState createState() => _AturJadwalPageState();
}

class _AturJadwalPageState extends State<AturJadwalPage> {
  List<Jadwal> _jadwal = [];
  List<MataKuliah> _mataKuliah = [];
  int? _userId;
  String? _selectedMK;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    
    try {
      final resp = await http.get(Uri.parse('https://ahmad2711.rf.gd/api/mk.php?user_id=$_userId'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success']) {
          final mkList = (data['mata_kuliah'] as List).map((e) => MataKuliah.fromJson(e)).toList();
          setState(() {
            _mataKuliah = mkList;
          });
          if (mkList.isNotEmpty) {
            await DataManager.saveMataKuliah(mkList);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading MK from API: $e');
      final cachedMK = await DataManager.loadMataKuliah();
      if (cachedMK.isNotEmpty) {
        setState(() {
          _mataKuliah = cachedMK;
        });
      }
    }

    List<Jadwal> jadwalList = [];
    try {
      final resp = await http.get(Uri.parse('https://ahmad2711.rf.gd/api/jadwal.php?user_id=$_userId'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success']) {
          jadwalList = (data['jadwal'] as List).map((e) => Jadwal.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading Jadwal from API: $e');
    }

    setState(() {
      _jadwal = jadwalList;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedMK = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  void _addJadwal() async {
    if (_selectedMK == null || _selectedDate == null || _selectedTime == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://ahmad2711.rf.gd/api/jadwal.php?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mata_kuliah': _selectedMK,
          'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'waktu': _selectedTime!.format(context),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _resetForm();
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _deleteJadwal(int index) async {
    final jadwal = _jadwal[index];
    if (jadwal.id != null && _userId != null) {
      try {
        final response = await http.delete(
          Uri.parse('https://ahmad2711.rf.gd/api/jadwal.php?user_id=$_userId&id=${jadwal.id}'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success']) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Jadwal berhasil dihapus')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Atur Jadwal'),
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
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                    Icons.schedule_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kelola Jadwal',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atur jadwal pembelajaran Anda dengan mudah',
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
                            'Tambah Jadwal Baru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedMK,
                            decoration: InputDecoration(
                              labelText: 'Mata Kuliah',
                              prefixIcon: const Icon(Icons.book_rounded, color: Color(0xFF667EEA)),
                              filled: true,
                              fillColor: const Color(0xFFF5F7FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            items: _mataKuliah.map((mk) {
                              return DropdownMenuItem<String>(
                                value: mk.nama,
                                child: Text(mk.nama),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMK = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _selectDate(context),
                                  icon: const Icon(Icons.calendar_today_rounded),
                                  label: Text(
                                    _selectedDate == null
                                        ? 'Pilih Tanggal'
                                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667EEA),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _selectTime(context),
                                  icon: const Icon(Icons.schedule_rounded),
                                  label: Text(
                                    _selectedTime == null ? 'Pilih Waktu' : _selectedTime!.format(context),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF764BA2),
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addJadwal,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tambah Jadwal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06D6A0),
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
                    // Jadwal List
                    if (_jadwal.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Jadwal Pembelajaran (${_jadwal.length})',
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
                        itemCount: _jadwal.length,
                        itemBuilder: (context, index) {
                          final j = _jadwal[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF667EEA).withOpacity(0.1),
                                  const Color(0xFF764BA2).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: const Color(0xFF667EEA),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667EEA).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.schedule_rounded,
                                    color: Color(0xFF667EEA),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        j.mataKuliah,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 13,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            j.tanggal,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 13,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            j.waktu,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded),
                                  color: Colors.red,
                                  onPressed: () => _deleteJadwal(index),
                                  splashRadius: 24,
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
                              Icons.calendar_today_rounded,
                              size: 64,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada jadwal',
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
