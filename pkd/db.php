<?php
$host = 'localhost';
$user = 'root';
$pass = '';
$charset = 'utf8mb4';

try {
    // Connect to MySQL server
    $pdo = new PDO("mysql:host=$host;charset=$charset", $user, $pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
    //echo "Connected to MySQL server successfully.<br>";

    // Create Database
    $pdo->exec("CREATE DATABASE IF NOT EXISTS feedback_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    //echo "Database 'feedback_system' created or already exists.<br>";

    // Switch to the feedback_system database
    $pdo->exec("USE feedback_system");

    // Create Users Table
    $createUsersTable = "
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'user') DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    ";
    $pdo->exec($createUsersTable);
    //echo "Table 'users' created successfully.<br>";

    // Create Feedback Table
    $createFeedbackTable = "
CREATE TABLE IF NOT EXISTS feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    feedback_text TEXT NOT NULL,
    status ENUM('Complete', 'Incomplete') DEFAULT 'Incomplete',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
";
    $pdo->exec($createFeedbackTable);
    //echo "Table 'feedback' created successfully.<br>";

} catch (PDOException $e) {
    die("Error: " . $e->getMessage());
}
?>