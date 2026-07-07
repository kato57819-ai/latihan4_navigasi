<?php
include 'config.php';

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(['error' => 'User ID required']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get mata kuliah
    $stmt = $conn->prepare("SELECT * FROM mata_kuliah WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $mk = [];
    while ($row = $result->fetch_assoc()) {
        $mk[] = $row;
    }
    echo json_encode(['success' => true, 'mata_kuliah' => $mk]);
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Add mata kuliah
    $data = json_decode(file_get_contents('php://input'), true);

    $nama = $data['nama'] ?? '';

    if (empty($nama)) {
        echo json_encode(['success' => false, 'message' => 'Nama mata kuliah wajib diisi']);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO mata_kuliah (user_id, nama) VALUES (?, ?)");
    $stmt->bind_param("is", $user_id, $nama);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Mata kuliah berhasil ditambahkan']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal menambahkan mata kuliah']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    // Delete mata kuliah
    $id = $_GET['id'] ?? null;
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'ID required']);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM mata_kuliah WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $id, $user_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Mata kuliah berhasil dihapus']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal menghapus mata kuliah']);
    }
} else {
    echo json_encode(['error' => 'Method not allowed']);
}

$conn->close();
?>