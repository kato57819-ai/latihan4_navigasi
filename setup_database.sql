-- Create database
CREATE DATABASE IF NOT EXISTS pengingat_tugas;
USE pengingat_tugas;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create profil table
CREATE TABLE IF NOT EXISTS profil (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    nama VARCHAR(100),
    nim VARCHAR(20),
    jurusan VARCHAR(100),
    semester VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create mata_kuliah table
CREATE TABLE IF NOT EXISTS mata_kuliah (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    kode_mk VARCHAR(20) NOT NULL,
    nama_mk VARCHAR(100) NOT NULL,
    sks INT,
    dosen VARCHAR(100),
    hari VARCHAR(20),
    jam_mulai TIME,
    jam_selesai TIME,
    ruangan VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create tugas table
CREATE TABLE IF NOT EXISTS tugas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    mata_kuliah_id INT,
    deskripsi VARCHAR(255) NOT NULL,
    due_date DATE NOT NULL,
    selesai BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (mata_kuliah_id) REFERENCES mata_kuliah(id) ON DELETE SET NULL
);

-- Create jadwal table
CREATE TABLE IF NOT EXISTS jadwal (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    mata_kuliah_id INT NOT NULL,
    hari VARCHAR(20),
    jam_mulai TIME,
    jam_selesai TIME,
    ruangan VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (mata_kuliah_id) REFERENCES mata_kuliah(id) ON DELETE CASCADE
);
