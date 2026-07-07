<?php
include 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $nama = $data['nama'] ?? '';
    $username = $data['username'] ?? '';
    $password = $data['password'] ?? '';

    if (empty($nama) || empty($username) || empty($password)) {
        echo json_encode(['success' => false, 'message' => 'Semua field wajib diisi']);
        exit;
    }

    // Hash password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    // Cek apakah username sudah ada
    $stmt = $conn->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        echo json_encode(['success' => false, 'message' => 'Username sudah digunakan']);
        exit;
    }

    // Insert user baru
    $stmt = $conn->prepare("INSERT INTO users (nama, username, password) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $nama, $username, $hashedPassword);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Pendaftaran berhasil']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal mendaftar']);
    }

    $stmt->close();
} else {
    echo json_encode(['error' => 'Method not allowed']);
}

$conn->close();
?>