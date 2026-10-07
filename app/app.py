import os
from flask import Flask, request, jsonify
import MySQLdb

app = Flask(__name__)

def get_db():
    return MySQLdb.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        user=os.environ.get('DB_USER', 'root'),
        passwd=os.environ.get('DB_PASSWORD', 'password'),
        db=os.environ.get('DB_NAME', 'fitness_tracker')
    )

@app.route('/')
def health():
    return jsonify({"status": "ok", "service": "fitness-tracker"}), 200

@app.route('/log', methods=['POST'])
def log_entry():
    data = request.get_json()
    weight = data.get('weight')
    water_liters = data.get('water_liters')
    calories = data.get('calories')
    notes = data.get('notes', '')

    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO entries (weight, water_liters, calories, notes) VALUES (%s, %s, %s, %s)",
        (weight, water_liters, calories, notes)
    )
    db.commit()
    entry_id = cursor.lastrowid
    cursor.close()
    db.close()

    return jsonify({"message": "Entry logged", "id": entry_id}), 201

@app.route('/history', methods=['GET'])
def history():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT id, weight, water_liters, calories, notes, created_at FROM entries ORDER BY created_at DESC LIMIT 50")
    rows = cursor.fetchall()
    cursor.close()
    db.close()

    entries = [
        {
            "id": r[0], "weight": r[1], "water_liters": r[2],
            "calories": r[3], "notes": r[4], "created_at": str(r[5])
        } for r in rows
    ]
    return jsonify(entries), 200

@app.route('/metrics')
def metrics():
    return "fitness_tracker_up 1\n", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
