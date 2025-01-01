<?php
session_start();
require 'db.php';

// Check if user is logged in and is an admin
if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'admin') {
    header('Location: index.php');
    exit;
}

// Fetch all feedback by default or based on filter
$filter_date = '';
$search = '';

if (isset($_POST['filter_date'])) {
    $filter_date = $_POST['filter_date'];
    if ($filter_date) {
        $stmt = $pdo->prepare("SELECT feedback.id, users.username, feedback.feedback_text, feedback.rating, feedback.status, feedback.created_at 
                               FROM feedback 
                               JOIN users ON feedback.user_id = users.id
                               WHERE DATE(feedback.created_at) = ?");
        $stmt->execute([$filter_date]);
        $all_feedbacks = $stmt->fetchAll();
    } else {
        // Fetch all feedback if no date is selected
        $stmt = $pdo->query("SELECT feedback.id, users.username, feedback.feedback_text, feedback.rating, feedback.status, feedback.created_at 
                             FROM feedback 
                             JOIN users ON feedback.user_id = users.id");
        $all_feedbacks = $stmt->fetchAll();
    }
} elseif (isset($_POST['search'])) {
    $search = $_POST['search'];
    $stmt = $pdo->prepare("SELECT feedback.id, users.username, feedback.feedback_text, feedback.rating, feedback.status, feedback.created_at 
                           FROM feedback 
                           JOIN users ON feedback.user_id = users.id
                           WHERE feedback.feedback_text LIKE ? 
                           OR users.username LIKE ? 
                           OR feedback.rating LIKE ? 
                           OR feedback.status LIKE ? 
                           OR DATE(feedback.created_at) LIKE ?");
    $search_term = "%$search%";
    $stmt->execute([$search_term, $search_term, $search_term, $search_term, $search_term]);
    $all_feedbacks = $stmt->fetchAll();
} else {
    $stmt = $pdo->query("SELECT feedback.id, users.username, feedback.feedback_text, feedback.rating, feedback.status, feedback.created_at 
                         FROM feedback 
                         JOIN users ON feedback.user_id = users.id");
    $all_feedbacks = $stmt->fetchAll();
}

// Handle status update
if (isset($_POST['update_status'])) {
    $status = $_POST['status'];
    $feedback_id = $_POST['feedback_id'];
    $stmt = $pdo->prepare('UPDATE feedback SET status = ? WHERE id = ?');
    $stmt->execute([$status, $feedback_id]);
    header('Location: dashboard.php');
    exit;
}

// Handle feedback deletion
if (isset($_GET['delete_id'])) {
    $feedback_id = $_GET['delete_id'];
    $stmt = $pdo->prepare('DELETE FROM feedback WHERE id = ?');
    $stmt->execute([$feedback_id]);
    header('Location: dashboard.php');
    exit;
}

function getRatingEmoji($rating) {
    $emojis = [
        1 => '😠',
        2 => '😞',
        3 => '😐',  
        4 => '😊',
        5 => '😁' 
    ];
    return $emojis[$rating] ?? 'No Rating'; // Default if rating is not set
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background-color: #f4f7f6;
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            box-sizing: border-box;
        }
        .container {
            background: #ffffff;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 15px rgba(0, 0, 0, 0.2);
            width: 100%;
            max-width: 1000px;
            box-sizing: border-box;
        }
        h1 {
            color: #333;
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            table-layout: fixed;
        }
        table th, table td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: left;
            word-wrap: break-word;
            overflow-wrap: break-word;
        }
        table th {
            background-color: #f2f2f2;
        }
        table tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        a, select, button, input[type="text"], .logout-btn {
            padding: 10px;
            border-radius: 5px;
            border: 1px solid #ccc;
            margin-right: 10px;
            width: 100%;
            max-width: 200px;
            box-sizing: border-box;
        }
        button, .logout-btn {
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }
        button:hover, .logout-btn:hover {
            background-color: #45a049;
        }
        a.delete-btn {
            background-color: #f44336;
            color: white;
            padding: 9px;
            border-radius: 5px;
            text-decoration: none;
            transition: background-color 0.3s ease;
            display: inline-block;
            text-align: center;
        }
        a.delete-btn:hover {
            background-color: #d32f2f;
        }
        .logout-btn {
            display: block;
            width: auto;
            padding: 10px 20px;
            margin: 20px auto 0;
            background-color: #f44336;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-align: center;
            text-decoration: none;
            transition: background-color 0.3s ease;
        }
        .form-group {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            justify-content: space-between;
        }
        @media (max-width: 768px) {
            .form-group select, .form-group input[type="text"], .form-group button {
                width: 100%;
                margin-bottom: 10px;
            }
            table th, table td {
                font-size: 14px;
                padding: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>All User Feedback</h1>

        <!-- Date Filter -->
        <form method="POST" style="margin-bottom: 20px;">
            <div class="form-group">
                <label for="filter_date">Select Date:</label>
                <input type="date" name="filter_date" id="filter_date" value="<?= htmlspecialchars($filter_date) ?>">
                <button type="submit">Apply</button>
            </div>
        </form>

        <!-- Search Form -->
        <form method="POST" style="margin-bottom: 20px;">
            <div class="form-group">
                <label for="search">Search:</label>
                <input type="text" name="search" id="search" placeholder="Search feedback or username" value="<?= htmlspecialchars($search) ?>">
                <button type="submit">Search</button>
            </div>
        </form>

        <table>
            <tr>
                <th>No.</th>
                <th>Username</th>
                <th>Feedback</th>
                <th>Rating</th>
                <th>Status</th>
                <th>Submitted At</th>
                <th>Actions</th>
            </tr>
            <?php $counter = 1; ?>
            <?php foreach ($all_feedbacks as $feedback): ?>
                <tr>
                    <td><?= $counter++ ?></td>
                    <td><?= $feedback['username'] ?></td>
                    <td><?= $feedback['feedback_text'] ?></td>
                    <td><?= isset($feedback['rating']) ? getRatingEmoji($feedback['rating']) : 'No Rating' ?></td>
                    <td><?= $feedback['status'] ?? 'Incomplete' ?></td>
                    <td><?= $feedback['created_at'] ?></td>
                    <td>
                        <form method="POST" style="display: inline;">
                            <select name="status">
                                <option value="Complete" <?= $feedback['status'] == 'Complete' ? 'selected' : '' ?>>Complete</option>
                                <option value="Incomplete" <?= $feedback['status'] == 'Incomplete' ? 'selected' : '' ?>>Incomplete</option>
                            </select>
                            <input type="hidden" name="feedback_id" value="<?= $feedback['id'] ?>">
                            <button type="submit" name="update_status">Update</button>
                        </form>

                        <a href="?delete_id=<?= $feedback['id'] ?>" class="delete-btn" onclick="return confirm('Are you sure you want to delete this feedback?')">Delete</a>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>

        <a href="logout.php" class="logout-btn">Logout</a>
    </div>
</body>
</html>
