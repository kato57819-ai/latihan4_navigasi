import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
import '../models/data_manager.dart';

class PengingatTugasPage extends StatefulWidget {
  final List<MataKuliah>? mataKuliahData;
  final List<Jadwal>? jadwalData;

  const PengingatTugasPage({
    super.key,
    this.mataKuliahData,
    this.jadwalData,
  });

  @override
  State<PengingatTugasPage> createState() => _PengingatTugasPageState();
}

class _PengingatTugasPageState extends State<PengingatTugasPage> {
  final TextEditingController _tugasController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Tugas> _tugas = [];
  List<MataKuliah> _mataKuliah = [];
  List<Jadwal> _jadwal = [];

  String? _selectedMK;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _searchQuery = '';

  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    print('Pengingat Tugas - User ID loaded: $_userId'); // Debug
    if (_userId != null) {
      _loadData();
    } else {
      print('Pengingat Tugas - User ID is null'); // Debug
    }
  }

  Future<void> _loadData() async {
    if (_userId == null) return;

    // Load MataKuliah from API
    try {
      final mkResponse = await http.get(Uri.parse('https://ahmad2711.rf.gd/api/mk.php?user_id=$_userId'));
      if (mkResponse.statusCode == 200) {
        final mkData = jsonDecode(mkResponse.body);
        if (mkData['success']) {
          _mataKuliah = (mkData['mata_kuliah'] as List).map((e) => MataKuliah.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading MK: $e');
    }

    // Load Jadwal from API
    try {
      final jadwalResponse = await http.get(Uri.parse('https://ahmad2711.rf.gd/api/jadwal.php?user_id=$_userId'));
      if (jadwalResponse.statusCode == 200) {
        final jadwalData = jsonDecode(jadwalResponse.body);
        if (jadwalData['success']) {
          _jadwal = (jadwalData['jadwal'] as List).map((e) => Jadwal.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading jadwal: $e');
    }

    // Load Tugas from API
    try {
      final tugasResponse = await http.get(Uri.parse('https://ahmad2711.rf.gd/api/tugas.php?user_id=$_userId'));
      if (tugasResponse.statusCode == 200) {
        final tugasData = jsonDecode(tugasResponse.body);
        if (tugasData['success']) {
          _tugas = (tugasData['tugas'] as List).map((e) => Tugas.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading tugas: $e');
    }

    setState(() {});
  }

  Future<void> _saveData() async {
    await DataManager.saveTugas(_tugas);
  }

  void _addTugas() async {
    if (_tugasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi deskripsi tugas')),
      );
      return;
    }

    if (_selectedMK == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
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
        Uri.parse('https://ahmad2711.rf.gd/api/tugas.php?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deskripsi': _tugasController.text,
          'mata_kuliah': _selectedMK,
          'tanggal': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
          'waktu': _selectedTime != null ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : null,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        _tugasController.clear();
        _selectedMK = null;
        _selectedDate = null;
        _selectedTime = null;
        _loadData(); // Reload
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tugas berhasil ditambahkan')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _editTugas(int index) {
    _tugasController.text = _tugas[index].deskripsi;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tugas'),
        content: TextField(
          controller: _tugasController,
          decoration: const InputDecoration(labelText: 'Deskripsi Tugas'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tugasController.clear();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tugas[index] = Tugas(
                  deskripsi: _tugasController.text,
                  selesai: _tugas[index].selesai,
                  mataKuliah: _tugas[index].mataKuliah,
                  tanggal: _tugas[index].tanggal,
                  waktu: _tugas[index].waktu,
                );
              });

              _saveData();
              _tugasController.clear();
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteTugas(int index) async {
    final tugasId = _tugas[index].id;
    if (tugasId == null || _userId == null) {
      // Fallback: hapus lokal saja jika tidak ada ID
      setState(() => _tugas.removeAt(index));
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('https://ahmad2711.rf.gd/api/tugas.php?user_id=$_userId&id=$tugasId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() => _tugas.removeAt(index));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dihapus')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${data['message']}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _toggleSelesai(int index) async {
    final tugasId = _tugas[index].id;
    if (tugasId == null || _userId == null) return;

    try {
      final response = await http.put(
        Uri.parse('https://ahmad2711.rf.gd/api/tugas.php?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': tugasId,
          'selesai': _tugas[index].selesai ? 0 : 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() => _tugas[index].selesai = !_tugas[index].selesai);
        }
      }
    } catch (e) {
      debugPrint('Error toggling selesai: $e');
    }
  }

  List<Tugas> get _filteredTugas {
    if (_searchQuery.isEmpty) return _tugas;
    return _tugas.where((t) => 
      t.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (t.mataKuliah?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFADD8E6),
      appBar: AppBar(
        title: const Text('Pengingat Tugas'),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFADD8E6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ===== INPUT TUGAS =====
              TextField(
                controller: _tugasController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Tugas',
                  prefixIcon: Icon(Icons.task, color: Color(0xFF7494EC)),
                ),
              ),

              const SizedBox(height: 12),

              // ===== DROPDOWN MATA KULIAH (FIXED) =====
              DropdownButtonFormField<String>(
                value: _selectedMK,
                decoration: InputDecoration(
                  labelText: 'Mata Kuliah (Opsional)',
                  prefixIcon:
                      const Icon(Icons.book, color: Color(0xFF7494EC)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                hint: _mataKuliah.isEmpty ? const Text('Belum ada Mata Kuliah') : const Text('Pilih Mata Kuliah'),
                items: _mataKuliah.isEmpty
                    ? []
                    : _mataKuliah.map((mk) {
                        return DropdownMenuItem<String>(
                          value: mk.nama,
                          child: Text(mk.nama),
                        );
                      }).toList(),
                onChanged: _mataKuliah.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMK = value;
                          _selectedDate = null;
                          _selectedTime = null;
                        });

                        if (value == null) return;

                        // Find jadwal matching selected MK
                        try {
                          final jadwal = _jadwal.firstWhere(
                            (j) => j.mataKuliah == value,
                          );
                          debugPrint('Found jadwal: ${jadwal.mataKuliah} - ${jadwal.tanggal} ${jadwal.waktu}');

                          setState(() {
                            // ---- PARSE TANGGAL ----
                            if (jadwal.tanggal.isNotEmpty) {
                              _selectedDate = DateTime.tryParse(jadwal.tanggal);
                              debugPrint('Parsed date: $_selectedDate');
                            }

                            // ---- PARSE WAKTU ----
                            if (jadwal.waktu.isNotEmpty && jadwal.waktu.contains(':')) {
                              final parts = jadwal.waktu.split(':');
                              if (parts.length >= 2) {
                                final h = int.tryParse(parts[0]);
                                final m = int.tryParse(parts[1]);
                                if (h != null && m != null) {
                                  _selectedTime = TimeOfDay(hour: h, minute: m);
                                  debugPrint('Parsed time: $_selectedTime');
                                }
                              }
                            }
                          });
                        } catch (e) {
                          debugPrint("Jadwal tidak ditemukan untuk MK: $value. Error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Jadwal tidak ditemukan untuk MK: $value')),
                          );
                        }
                      },
              ),

              const SizedBox(height: 16),

              // ===== DISPLAY TANGGAL & WAKTU =====
              if (_selectedDate != null || _selectedTime != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7494EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedDate != null)
                        Text(
                          'Tanggal: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      if (_selectedTime != null && _selectedDate != null)
                        const SizedBox(height: 8),
                      if (_selectedTime != null)
                        Text(
                          'Waktu: ${_selectedTime!.format(context)}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // ===== BUTTON TAMBAH =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTugas,
                  child: const Text('Tambah Tugas'),
                ),
              ),

              const SizedBox(height: 12),

              // ===== SEARCH TUGAS =====
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  labelText: 'Cari Tugas',
                  hintText: 'Cari berdasarkan deskripsi atau mata kuliah',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF7494EC)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7494EC)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== LIST TUGAS =====
              Expanded(
                child: _filteredTugas.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Belum ada tugas'
                              : 'Tidak ada tugas yang cocok',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTugas.length,
                        itemBuilder: (context, index) {
                          final tugas = _filteredTugas[index];
                          final originalIndex = _tugas.indexOf(tugas);

                          return Card(
                            color: tugas.selesai
                                ? const Color.fromARGB(255, 3, 45, 109)
                                : const Color.fromARGB(255, 107, 124, 172),
                            child: ListTile(
                              leading: Checkbox(
                                value: tugas.selesai,
                                onChanged: (_) => _toggleSelesai(originalIndex),
                                activeColor: Colors.white,
                                checkColor: const Color.fromARGB(255, 107, 124, 172),
                        ),
                        title: Text(
                          tugas.deskripsi,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: tugas.selesai
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tugas.mataKuliah != null)
                              Text('MK: ${tugas.mataKuliah}',
                                  style: const TextStyle(
                                      color: Colors.white70)),

                            if (tugas.tanggal != null)
                              Text(
                                'Tanggal: ${DateFormat('yyyy-MM-dd').format(tugas.tanggal!)}',
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),

                            if (tugas.waktu != null)
                              Text(
                                'Waktu: ${tugas.waktu!.format(context)}',
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.white),
                              onPressed: () => _editTugas(originalIndex),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.white),
                              onPressed: () => _deleteTugas(originalIndex),
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
        ),
      ),
    );
  }

}
