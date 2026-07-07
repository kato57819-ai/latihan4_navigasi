<?php
header('Content-Type: application/json');
include 'config.php';

// Get table structure
$sql = "DESCRIBE profil";
$result = $conn->query($sql);

if ($result) {
    $columns = [];
    while($row = $result->fetch_assoc()) {
        $columns[] = $row;
    }
    echo json_encode(['columns' => $columns]);
} else {
    echo json_encode(['error' => $conn->error]);
}

$conn->close();
?>
