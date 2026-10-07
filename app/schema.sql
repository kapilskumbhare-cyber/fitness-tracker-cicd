CREATE DATABASE IF NOT EXISTS fitness_tracker;
USE fitness_tracker;

CREATE TABLE IF NOT EXISTS entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    weight FLOAT,
    water_liters FLOAT,
    calories INT,
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
