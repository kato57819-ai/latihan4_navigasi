<?php
include 'config.php';

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(['error' => 'User ID required']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get tugas
    $stmt = $conn->prepare("SELECT * FROM tugas WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $tugas = [];
    while ($row = $result->fetch_assoc()) {
        $tugas[] = $row;
    }
    echo json_encode(['success' => true, 'tugas' => $tugas]);
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Add tugas
    $data = json_decode(file_get_contents('php://input'), true);

    $deskripsi = $data['deskripsi'] ?? '';
    $mata_kuliah = $data['mata_kuliah'] ?? null;
    $tanggal = $data['tanggal'] ?? null;
    $waktu = $data['waktu'] ?? null;

    if (empty($deskripsi)) {
        echo json_encode(['success' => false, 'message' => 'Deskripsi tugas wajib diisi']);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO tugas (user_id, deskripsi, mata_kuliah, tanggal, waktu, selesai) VALUES (?, ?, ?, ?, ?, 0)");
    $stmt->bind_param("issss", $user_id, $deskripsi, $mata_kuliah, $tanggal, $waktu);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Tugas berhasil ditambahkan']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal menambahkan tugas']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    // Update tugas (misal mark as done)
    $data = json_decode(file_get_contents('php://input'), true);
    $id = $data['id'] ?? null;
    $selesai = $data['selesai'] ?? false;

    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'ID required']);
        exit;
    }

    $stmt = $conn->prepare("UPDATE tugas SET selesai = ? WHERE id = ? AND user_id = ?");
    $stmt->bind_param("iii", $selesai, $id, $user_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Tugas berhasil diperbarui']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal memperbarui tugas']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    // Delete tugas
    $id = $_GET['id'] ?? null;
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'ID required']);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM tugas WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $id, $user_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Tugas berhasil dihapus']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal menghapus tugas']);
    }
} else {
    echo json_encode(['error' => 'Method not allowed']);
}

$conn->close();
?>