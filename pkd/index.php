<?php
session_start();
require 'db.php';

$error = '';

// Handle login form submission
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = trim($_POST['username']);
    $password = trim($_POST['password']);

    // Check credentials in the database
    $stmt = $pdo->prepare('SELECT * FROM users WHERE username = ?');
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
        // Successful login
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['role'] = $user['role'];
        
        // Redirect based on role
        if ($user['role'] == 'admin') {
            header('Location: dashboard.php');
        } else {
            header('Location: feedback.php');
        }
        exit;
    } else {
        // Invalid credentials
        $error = "Invalid username or password.";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #e0f7fa;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        .login-form {
            background: #fff;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 15px rgba(0, 0, 0, 0.2);
            width: 350px;
            text-align: center;
        }
        .login-form img {
            width: 100px;
            margin-bottom: 20px;
        }
        .login-form h1 {
            margin-bottom: 25px;
            font-size: 24px;
            color: #00796b;
        }
        .login-form input {
            width: 100%;
            padding: 12px;
            margin: 10px 0;
            border: 1px solid #b0bec5;
            border-radius: 5px;
            box-sizing: border-box;
            color: black; /* Ensure text is always black */
        }
        .login-form input.error {
            border-color: red;
            background-image: url('data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"%3E%3Cpath fill="%23FF0000" d="M8 1a7 7 0 100 14A7 7 0 008 1zm-.25 3h.5c.14 0 .25.11.25.25v4.5c0 .14-.11.25-.25.25h-.5a.25.25 0 01-.25-.25v-4.5c0-.14.11-.25.25-.25zm0 7h.5a.5.5 0 010 1h-.5a.5.5 0 010-1z"/%3E%3C/svg%3E');
            background-repeat: no-repeat;
            background-position: right 12px center;
            background-size: 20px;
        }
        .login-form button {
            width: 100%;
            padding: 12px;
            background: #00796b;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        .login-form button:hover {
            background: #004d40;
        }
        .error {
            color: red;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <form class="login-form" id="loginForm" method="POST" action="" novalidate>
        <img src="Logo.png" alt="PKD SMART Logo">
        <h1>Login</h1>
        <input type="text" name="username" id="username" placeholder="Username" required>
        <input type="password" name="password" id="password" placeholder="Password" required>
        <button type="submit">Login</button>
        <?php if ($error): ?>
            <p class="error"><?= $error ?></p>
        <?php endif; ?>
    </form>

    <script>
        // Function to handle validation and apply styles
        document.getElementById('loginForm').addEventListener('submit', function(event) {
            let username = document.getElementById('username');
            let password = document.getElementById('password');

            // Reset previous error styles
            username.classList.remove('error');
            password.classList.remove('error');

            // Check if fields are empty
            if (!username.value.trim()) {
                username.classList.add('error');
            }

            if (!password.value.trim()) {
                password.classList.add('error');
            }

            // If either field is empty, prevent form submission
            if (!username.value.trim() || !password.value.trim()) {
                event.preventDefault();
            }
        });
    </script>
</body>
</html>