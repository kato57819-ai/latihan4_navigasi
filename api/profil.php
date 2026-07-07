<?php
header('Content-Type: application/json');
include 'config.php';

try {
    // Auto-create profil table if not exists
    $createTableSQL = "CREATE TABLE IF NOT EXISTS profil (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL UNIQUE,
        nama VARCHAR(100),
        nim VARCHAR(20),
        jurusan VARCHAR(100),
        semester VARCHAR(10),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";

    if (!$conn->query($createTableSQL)) {
        // Table creation failed, might mean user_id column doesn't exist
        // Try to add it
        $addColumnSQL = "ALTER TABLE profil ADD COLUMN user_id INT UNIQUE NOT NULL DEFAULT 0 FIRST";
        @$conn->query($addColumnSQL); // Suppress error if column already exists
    }

    $user_id = $_GET['user_id'] ?? null;

    if (!$user_id) {
        echo json_encode(['error' => 'User ID required']);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Get profil
        $stmt = $conn->prepare("SELECT * FROM profil WHERE user_id = ?");
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $profil = $result->fetch_assoc();
            echo json_encode(['success' => true, 'profil' => $profil]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Profil tidak ditemukan']);
        }
        $stmt->close();

    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Update profil
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);

        if (!$data) {
            echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
            exit;
        }

        $nama = trim($data['nama'] ?? '');
        $nim = trim($data['nim'] ?? '');
        $jurusan = trim($data['jurusan'] ?? '');
        $semester = trim($data['semester'] ?? '');

        if (empty($nama) || empty($nim) || empty($jurusan) || empty($semester)) {
            echo json_encode(['success' => false, 'message' => 'Semua field wajib diisi']);
            exit;
        }

        // Check if profile exists
        $checkStmt = $conn->prepare("SELECT id FROM profil WHERE user_id = ?");
        $checkStmt->bind_param("i", $user_id);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        $checkStmt->close();

        if ($checkResult->num_rows > 0) {
            // Update existing profile
            $stmt = $conn->prepare("UPDATE profil SET nama = ?, nim = ?, jurusan = ?, semester = ?, updated_at = NOW() WHERE user_id = ?");
            if (!$stmt) {
                echo json_encode(['success' => false, 'message' => 'Prepare failed: ' . $conn->error]);
                exit;
            }
            $stmt->bind_param("ssssi", $nama, $nim, $jurusan, $semester, $user_id);
        } else {
            // Create new profile
            $stmt = $conn->prepare("INSERT INTO profil (user_id, nama, nim, jurusan, semester) VALUES (?, ?, ?, ?, ?)");
            if (!$stmt) {
                echo json_encode(['success' => false, 'message' => 'Prepare failed: ' . $conn->error]);
                exit;
            }
            $stmt->bind_param("issss", $user_id, $nama, $nim, $jurusan, $semester);
        }

        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Profil berhasil disimpan']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Execute failed: ' . $stmt->error]);
        }
        $stmt->close();

    } else {
        echo json_encode(['error' => 'Method not allowed']);
    }

} catch (Exception $e) {
    echo json_encode(['error' => 'Exception: ' . $e->getMessage()]);
}

$conn->close();
?>