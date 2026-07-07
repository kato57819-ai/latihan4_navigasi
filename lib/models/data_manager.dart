import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'data_models.dart';

class DataManager {
  static const String _mkKey = 'mata_kuliah';
  static const String _jadwalKey = 'jadwal';
  static const String _tugasKey = 'tugas';
  static const String _profilKey = 'profil';

  // Mata Kuliah
  static Future<List<MataKuliah>> loadMataKuliah() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_mkKey);
    if (data != null) {
      final list = json.decode(data) as List;
      return list.map((e) => MataKuliah.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> saveMataKuliah(List<MataKuliah> mk) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(mk.map((e) => e.toJson()).toList());
    await prefs.setString(_mkKey, data);
  }

  // Jadwal
  static Future<List<Jadwal>> loadJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_jadwalKey);
    if (data != null) {
      final list = json.decode(data) as List;
      return list.map((e) => Jadwal.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> saveJadwal(List<Jadwal> jadwal) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(jadwal.map((e) => e.toJson()).toList());
    await prefs.setString(_jadwalKey, data);
  }

  // Tugas
  static Future<List<Tugas>> loadTugas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tugasKey);
    if (data != null) {
      final list = json.decode(data) as List;
      return list.map((e) => Tugas.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> saveTugas(List<Tugas> tugas) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(tugas.map((e) => e.toJson()).toList());
    await prefs.setString(_tugasKey, data);
  }

  // Profil
  static Future<Profil> loadProfil() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profilKey);
    if (data != null) {
      return Profil.fromJson(json.decode(data));
    }
    return Profil(
      nama: 'John Doe',
      nim: '123456789',
      jurusan: 'Teknik Informatika',
      semester: '4',
    );
  }

  static Future<void> saveProfil(Profil profil) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(profil.toJson());
    await prefs.setString(_profilKey, data);
  }
}
