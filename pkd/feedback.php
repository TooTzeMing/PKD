<?php
session_start();
require 'db.php';

// Check if user is logged in and is not an admin
if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'user') {
    header('Location: index.php');
    exit;
}

$user_id = $_SESSION['user_id'];

// Fetch all feedback submitted by the logged-in user
$stmt = $pdo->prepare('SELECT * FROM feedback WHERE user_id = ? ORDER BY created_at DESC');
$stmt->execute([$user_id]);
$user_feedbacks = $stmt->fetchAll();


// Handle new feedback submission or editing
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $feedback_text = $_POST['feedback'] ?? null;
    $rating = $_POST['rating'] ?? null;
    $edit_id = $_POST['edit_id'] ?? null;

    if ($feedback_text && $rating && $rating >= 1 && $rating <= 5) {
        if ($edit_id) {
            // Update existing feedback
            $stmt = $pdo->prepare('UPDATE feedback SET feedback_text = ?, rating = ? WHERE id = ? AND user_id = ?');
            $stmt->execute([$feedback_text, $rating, $edit_id, $user_id]);

        } else {
            // Submit new feedback
            $stmt = $pdo->prepare('INSERT INTO feedback (user_id, feedback_text, rating, status, created_at) VALUES (?, ?, ?, "Incomplete", NOW())');
            $stmt->execute([$user_id, $feedback_text, $rating]);

        }
        header('Location: feedback.php');
        exit;
    }
}

// If editing, fetch the existing feedback
$edit_feedback = null;
if (isset($_GET['edit_id'])) {
    $edit_id = $_GET['edit_id'];
    $stmt = $pdo->prepare('SELECT * FROM feedback WHERE id = ? AND user_id = ?');
    $stmt->execute([$edit_id, $user_id]);
    $edit_feedback = $stmt->fetch();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Feedback</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background-color: #f4f7f6;
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .container {
            background: #ffffff;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 15px rgba(0, 0, 0, 0.2);
            width: 80%;
            max-width: 800px;
        }
        h1, h2 {
            color: #333;
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        table th, table td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        textarea, button {
            width: 100%;
            padding: 12px;
            margin: 10px 0;
            border-radius: 5px;
            border: 1px solid #ccc;
            font-size: 16px;
        }
        textarea.error {
            border-color: red;
        }
        .error-message {
            color: red;
            font-size: 14px;
            display: none;
            margin-top: 5px;
        }
        .rating {
            display: flex;
            justify-content: center;
            margin-bottom: 10px;
            position: relative;
        }
        .invalid-icon {
            background-image: url('data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"%3E%3Cpath fill="%23FF0000" d="M8 1a7 7 0 100 14A7 7 0 008 1zm-.25 3h.5c.14 0 .25.11.25.25v4.5c0 .14-.11.25-.25.25h-.5a.25.25 0 01-.25-.25v-4.5c0-.14.11-.25.25-.25zm0 7h.5a.5.5 0 010 1h-.5a.5.5 0 010-1z"/%3E%3C/svg%3E');
            background-size: contain;
            background-repeat: no-repeat;
            width: 20px;
            height: 20px;
            position: absolute;
            right: -25px;
            top: 50%;
            transform: translateY(-50%);
            display: none;
        }
        button {
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }
        button:hover {
            background-color: #45a049;
        }
        .logout-btn {
            background-color: #f44336;
            color: white;
            padding: 10px 20px;
            border-radius: 5px;
            text-align: center;
            text-decoration: none;
            margin: 20px auto 0;
            display: block;
        }
        .logout-btn:hover {
            background-color: #d32f2f;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Your Feedback</h1>
        <table>
            <tr>
                <th>No.</th>
                <th>Feedback</th>
                <th>Rating</th>
                <th>Submitted At</th>
                <th>Actions</th>
            </tr>
            <?php foreach ($user_feedbacks as $index => $feedback): ?>
                <tr>
                    <td><?= $index + 1 ?></td>
                    <td><?= htmlspecialchars($feedback['feedback_text']) ?></td>
                    <td><?= ['😠', '😞', '😐', '😊', '😁'][$feedback['rating'] - 1] ?></td>
                    <td><?= $feedback['created_at'] ?></td>
                    <td>
                        <?php if ($feedback['status'] === 'Complete'): ?>
                            <span style="cursor: not-allowed; color: #aaa;">Disabled</span>
                        <?php else: ?>
                            <a href="?edit_id=<?= $feedback['id'] ?>">Edit</a>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>

        <h2><?= isset($edit_feedback) ? 'Edit Feedback' : 'Submit New Feedback' ?></h2>
        <form method="POST" onsubmit="return validateForm()">
            <input type="hidden" name="edit_id" value="<?= htmlspecialchars($edit_feedback['id'] ?? '') ?>">
            <div style="position: relative;">
                <textarea name="feedback" placeholder="Enter your feedback here"><?= htmlspecialchars($edit_feedback['feedback_text'] ?? '') ?></textarea>
                <span class="invalid-icon" id="feedback-icon"></span>
            </div>
            <div class="error-message" id="feedback-error">
                Feedback is required.
            </div>
            <div class="rating">
                <?php
                $emojis = ['😠', '😞', '😐', '😊', '😁'];
                foreach ($emojis as $i => $emoji):
                    $checked = (isset($edit_feedback['rating']) && $edit_feedback['rating'] == $i + 1) ? 'checked' : '';
                    echo "<input type='radio' id='rating" . ($i + 1) . "' name='rating' value='" . ($i + 1) . "' $checked>";
                    echo "<label for='rating" . ($i + 1) . "'>$emoji</label>";
                endforeach;
                ?>
                <span class="invalid-icon" id="rating-icon"></span>
            </div>
            <div class="error-message" id="rating-error">
                Please select a rating.
            </div>
            <button type="submit">Submit Feedback</button>
        </form>
        <a href="logout.php" class="logout-btn">Logout</a>
    </div>
    <script>
        function validateForm() {
            let isValid = true;

            // Validate feedback text
            const feedback = document.querySelector('textarea[name="feedback"]');
            const feedbackError = document.getElementById('feedback-error');
            const feedbackIcon = document.getElementById('feedback-icon');
            if (!feedback.value.trim()) {
                feedback.classList.add('error');
                feedbackError.style.display = 'block';
                feedbackIcon.style.display = 'inline-block';
                isValid = false;
            } else {
                feedback.classList.remove('error');
                feedbackError.style.display = 'none';
                feedbackIcon.style.display = 'none';
            }

            // Validate rating selection
            const ratings = document.getElementsByName('rating');
            let ratingSelected = false;
            for (const rating of ratings) {
                if (rating.checked) {
                    ratingSelected = true;
                    break;
                }
            }
            const ratingError = document.getElementById('rating-error');
            const ratingIcon = document.getElementById('rating-icon');
            if (!ratingSelected) {
                ratingError.style.display = 'block';
                ratingIcon.style.display = 'inline-block';
                isValid = false;
            } else {
                ratingError.style.display = 'none';
                ratingIcon.style.display = 'none';
            }

            return isValid;
        }
    </script>
</body>
</html>