<?php
$data = json_encode([
    'nama' => 'Test User',
    'username' => 'testuser',
    'password' => '123456'
]);

$opts = [
    'http' => [
        'method' => 'POST',
        'header' => 'Content-Type: application/json',
        'content' => $data
    ]
];

$context = stream_context_create($opts);
$result = file_get_contents('http://localhost/api/register.php', false, $context);
echo $result;
?>