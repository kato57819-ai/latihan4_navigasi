<?php
include 'config.php';

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(['error' => 'User ID required']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get jadwal
    $stmt = $conn->prepare("SELECT * FROM jadwal WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $jadwal = [];
    while ($row = $result->fetch_assoc()) {
        $jadwal[] = $row;
    }
    echo json_encode(['success' => true, 'jadwal' => $jadwal]);
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Add jadwal
    $data = json_decode(file_get_contents('php://input'), true);

    $mata_kuliah = $data['mata_kuliah'] ?? '';
    $tanggal = $data['tanggal'] ?? '';
    $waktu = $data['waktu'] ?? '';

    if (empty($mata_kuliah) || empty($tanggal) || empty($waktu)) {
        echo json_encode(['success' => false, 'message' => 'Semua field wajib diisi']);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO jadwal (user_id, mata_kuliah, tanggal, waktu) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("isss", $user_id, $mata_kuliah, $tanggal, $waktu);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Jadwal berhasil ditambahkan']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal menambahkan jadwal']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    // Update jadwal
    $data = json_decode(file_get_contents('php://input'), true);
    $id = $data['id'] ?? null;
    $mata_kuliah = $data['mata_kuliah'] ?? '';
    $tanggal = $data['tanggal'] ?? '';
    $waktu = $data['waktu'] ?? '';

    if (!$id || empty($mata_kuliah) || empty($tanggal) || empty($waktu)) {
        echo json_encode(['success' => false, 'message' => 'Semua field wajib diisi']);
        exit;
    }

    $stmt = $conn->prepare("UPDATE jadwal SET mata_kuliah = ?, tanggal = ?, waktu = ? WHERE id = ? AND user_id = ?");
    $stmt->bind_param("sssii", $mata_kuliah, $tanggal, $waktu, $id, $user_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Jadwal berhasil diperbarui']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal memperbarui jadwal']);
    }
    // Delete jadwal
    $id = $_GET['id'] ?? null;
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'ID required']);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM jadwal WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $id, $user_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Jadwal berhasil dihapus']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal menghapus jadwal']);
    }
} else {
    echo json_encode(['error' => 'Method not allowed']);
}

$conn->close();
?>