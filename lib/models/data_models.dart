import 'package:flutter/material.dart';

class MataKuliah {
  int? id;
  String nama;

  MataKuliah({this.id, required this.nama});

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama};

  factory MataKuliah.fromJson(Map<String, dynamic> json) {
    return MataKuliah(
      id: json['id'],
      nama: json['nama'],
    );
  }
}

class Jadwal {
  int? id;
  String mataKuliah;
  String tanggal;
  String waktu;

  Jadwal({
    this.id,
    required this.mataKuliah,
    required this.tanggal,
    required this.waktu,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'mataKuliah': mataKuliah,
    'tanggal': tanggal,
    'waktu': waktu,
  };

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      id: json['id'],
      mataKuliah: json['mata_kuliah'] ?? '',
      tanggal: json['tanggal'] ?? '',
      waktu: json['waktu'] ?? '',
    );
  }
}

class Tugas {
  int? id;
  String deskripsi;
  String? mataKuliah; // Tambahkan field ini
  DateTime? tanggal;
  TimeOfDay? waktu;
  bool selesai;

  Tugas({
    this.id,
    required this.deskripsi,
    this.mataKuliah,
    this.tanggal,
    this.waktu,
    this.selesai = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deskripsi': deskripsi,
    'mataKuliah': mataKuliah,
    'tanggal': tanggal?.toIso8601String(),
    'waktu': waktu != null ? '${waktu!.hour}:${waktu!.minute}' : null,
    'selesai': selesai,
  };

  factory Tugas.fromJson(Map<String, dynamic> json) {
    TimeOfDay? waktu;
    if (json['waktu'] != null) {
      final parts = json['waktu'].toString().split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          waktu = TimeOfDay(hour: h, minute: m);
        }
      }
    }
    return Tugas(
      id: json['id'],
      deskripsi: json['deskripsi'] ?? json['deskripsi_tugas'] ?? '',
      mataKuliah: json['mataKuliah'] ?? json['mata_kuliah'],
      tanggal: json['tanggal'] != null ? DateTime.tryParse(json['tanggal']) : null,
      waktu: waktu,
      selesai: json['selesai'] is int
          ? (json['selesai'] == 1)
          : (json['selesai'] == true || json['selesai'] == 'true')
              ? true
              : false,
    );
  }
}

class Profil {
  String nama;
  String nim;
  String jurusan;
  String semester;

  Profil({
    required this.nama,
    required this.nim,
    required this.jurusan,
    required this.semester,
  });

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'nim': nim,
    'jurusan': jurusan,
    'semester': semester,
  };

  factory Profil.fromJson(Map<String, dynamic> json) {
    return Profil(
      nama: json['nama'] ?? 'John Doe',
      nim: json['nim'] ?? '123456789',
      jurusan: json['jurusan'] ?? 'Teknik Informatika',
      semester: json['semester'] ?? '4',
    );
  }
}
