<?php
require 'db.php';

try {
   
    // Get user ID for feedback insertion
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->execute(['user']);
    $userId = $stmt->fetchColumn();

    if ($userId) {
        // Insert feedback
        $pdo->exec("
            INSERT INTO feedback (user_id, feedback_text) 
            VALUES 
            ($userId, 'This is a sample feedback message from the user.')
        ");
        echo "Feedback inserted successfully.<br>";
    } else {
        echo "User not found for feedback insertion.<br>";
    }
} catch (PDOException $e) {
    die("Error: " . $e->getMessage());
}
?>