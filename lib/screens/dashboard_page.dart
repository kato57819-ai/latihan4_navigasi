import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'input_mk_page.dart';
import 'atur_jadwal_page.dart';
import 'pengingat_tugas_page.dart';
import 'laporan_tugas_page.dart';
import 'profil_page.dart';
import 'login_page.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/data_models.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Tugas> _tugas = [];
  bool _loading = false;
  int? _userId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    _loadTugas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTugas();
  }

  Future<void> _loadTugas() async {
    if (_userId == null) return;
    
    setState(() => _loading = true);
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
    setState(() => _loading = false);
  }

  int get _totalTugas => _tugas.length;
  int get _selesai => _tugas.where((t) => t.selesai).length;
  int get _belumSelesai => _totalTugas - _selesai;
  double get _progress => _totalTugas == 0 ? 0 : (_selesai / _totalTugas) * 100;

  List<Tugas> get _listSelesai => _tugas.where((t) => t.selesai).toList();
  List<Tugas> get _listBelum => _tugas.where((t) => !t.selesai).toList();

  List<Tugas> get _listBelumFiltered {
    if (_searchQuery.isEmpty) return _listBelum;
    return _listBelum
        .where((t) => t.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (t.mataKuliah?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFADD8E6),

      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadTugas,
          )
        ],
      ),

      drawer: _buildDrawer(context),

      body: RefreshIndicator(
        onRefresh: _loadTugas,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ===== HERO =====
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 36),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/1.jpg'),
                    fit: BoxFit.cover,
                    opacity: 0.6,
                  ),
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6).withOpacity(0.8), Color(0xFF06B6D4).withOpacity(0.8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.auto_stories_rounded,
                        size: 86, color: Colors.white),
                    SizedBox(height: 14),
                    Text(
                      "Selamat Datang 👋",
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Pantau progres tugas kuliahmu hari ini",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // ===== CONTENT =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _R(
                  child: Column(
                    children: [
                      _buildSummaryCard(context),
                      const SizedBox(height: 24),
                      _buildBelumSelesaiList(),
                      const SizedBox(height: 24),
                      _buildSelesaiList(),
                    ],
                  ),
                ),
              ),
            ),

            const SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox(height: 200),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LOADING WRAPPER =================

  Widget _R({required Widget child}) {
    if (_loading && _tugas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return child;
  }

  // ================= SUMMARY =================

  Widget _buildSummaryCard(BuildContext context) {
    double chartSize = MediaQuery.of(context).size.width < 600 ? 150 : 190;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/2.jpg'),
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Progres Tugas",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 18),

          // Display image or chart
          SizedBox(
            height: chartSize + 40,
            child: _totalTugas == 0
                ? Center(
                    child: Image.asset(
                      'assets/images/1.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: 1,
                                title: "Kosong",
                                color: Colors.grey,
                                radius: chartSize / 3,
                                titleStyle: const TextStyle(color: Colors.white),
                              ),
                            ],
                            sectionsSpace: 3,
                            centerSpaceRadius: chartSize / 6,
                          ),
                        );
                      },
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: _selesai.toDouble(),
                          title: "$_selesai\nSelesai",
                          color: const Color(0xFF10B981),
                          radius: chartSize / 3,
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          badgeWidget: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          ),
                          badgePositionPercentageOffset: 0.98,
                        ),
                        PieChartSectionData(
                          value: _belumSelesai.toDouble(),
                          title: "$_belumSelesai\nProses",
                          color: const Color(0xFF3B82F6),
                          radius: chartSize / 3,
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          badgeWidget: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: const Icon(Icons.schedule, color: Colors.white, size: 20),
                          ),
                          badgePositionPercentageOffset: 0.98,
                        ),
                      ],
                      sectionsSpace: 4,
                      centerSpaceRadius: chartSize / 6,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                        enabled: true,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _totalTugas == 0
                  ? "Belum ada tugas"
                  : "${_progress.toStringAsFixed(1)}% tugas selesai",
              style: const TextStyle(
                color: Color(0xFF3B5EDF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BELUM =================

  Widget _buildBelumSelesaiList() {
    if (_listBelum.isEmpty) {
      return _emptyBox("🎉 Semua tugas sudah selesai!");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== SEARCH FIELD =====
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Cari tugas atau MK...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF3B5EDF)),
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
              borderSide: const BorderSide(color: Color(0xFF3B5EDF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ===== TASK CARD =====
        _taskCard(
          title: "⏳ Belum Selesai (${_listBelumFiltered.length})",
          color: const Color(0xFF3B5EDF),
          list: _listBelumFiltered,
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }

  // ================= SELESAI =================

  Widget _buildSelesaiList() {
    if (_listSelesai.isEmpty) {
      return _emptyBox("Belum ada tugas yang selesai");
    }

    return _taskCard(
      title: "✅ Selesai",
      color: Colors.green,
      list: _listSelesai,
      icon: Icons.verified_rounded,
      isDone: true,
    );
  }

  // ================= CARD TEMPLATE =================

  Widget _taskCard({
    required String title,
    required Color color,
    required List<Tugas> list,
    required IconData icon,
    bool isDone = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...list.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.withOpacity(0.08)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    t.deskripsi,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: t.mataKuliah != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            children: [
                              Chip(
                                label: Text(t.mataKuliah!),
                                backgroundColor: Colors.white,
                                shape: StadiumBorder(
                                  side: BorderSide(color: color),
                                ),
                              ),
                              Chip(
                                label: Text(isDone ? "Selesai" : "Proses"),
                                backgroundColor:
                                    color.withOpacity(0.15),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              )),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ================= DRAWER =================

  Drawer _buildDrawer(BuildContext context) {
    final menuItems = [
      {'icon': Icons.book_rounded, 'title': 'Input MK', 'page': const InputMKPage(), 'color': 0xFF6366F1},
      {'icon': Icons.schedule_rounded, 'title': 'Atur Jadwal', 'page': const AturJadwalPage(), 'color': 0xFF8B5CF6},
      {'icon': Icons.notifications_active_rounded, 'title': 'Pengingat Tugas', 'page': const PengingatTugasPage(), 'color': 0xFFEC4899},
      {'icon': Icons.assessment_rounded, 'title': 'Laporan Tugas', 'page': const LaporanTugasPage(), 'color': 0xFF06B6D4},
      {'icon': Icons.person_rounded, 'title': 'Profil Mahasiswa', 'page': const ProfilPage(), 'color': 0xFF14B8A6},
    ];

    return Drawer(
      child: Column(
        children: [
          // Header dengan gradient
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B5EDF), Color(0xFF6C8CFF)],
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
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Menu Navigasi",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kelola tugas kuliahmu",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _modernNavItem(
                  context,
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  page: item['page'] as Widget,
                  color: Color(item['color'] as int),
                );
              },
            ),
          ),
          // Logout button
          Container(
            padding: const EdgeInsets.all(12),
            child: Material(
              child: InkWell(
                onTap: () => _logout(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: color.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
