<?php
include 'api/config.php';

if ($conn->connect_error) {
    echo "Koneksi gagal: " . $conn->connect_error;
} else {
    echo "Koneksi database berhasil!";
}

$conn->close();
?>