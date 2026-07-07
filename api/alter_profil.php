<?php
include 'config.php';

// Add user_id column to profil table if not exists
$alterSQL = "ALTER TABLE profil ADD COLUMN user_id INT UNIQUE NOT NULL DEFAULT 0";

// Check if column exists first
$checkSQL = "SHOW COLUMNS FROM profil LIKE 'user_id'";
$result = $conn->query($checkSQL);

if ($result && $result->num_rows == 0) {
    // Column doesn't exist, add it
    if ($conn->query($alterSQL)) {
        echo json_encode(['success' => true, 'message' => 'Kolom user_id berhasil ditambahkan']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Error: ' . $conn->error]);
    }
} else {
    echo json_encode(['success' => true, 'message' => 'Kolom user_id sudah ada']);
}

$conn->close();
?>
