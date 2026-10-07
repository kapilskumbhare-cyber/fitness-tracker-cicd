import sys
import types
from unittest.mock import MagicMock

import pytest

# Fake MySQLdb before app.py is imported, so tests need only Flask + pytest.
fake_mysqldb = types.ModuleType("MySQLdb")
fake_mysqldb.connect = MagicMock()
sys.modules["MySQLdb"] = fake_mysqldb

import app as app_module  # noqa: E402


@pytest.fixture
def client():
    app_module.app.config["TESTING"] = True
    fake_mysqldb.connect.reset_mock()
    return app_module.app.test_client()


def test_health(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok", "service": "fitness-tracker"}


def test_metrics(client):
    r = client.get("/metrics")
    assert r.status_code == 200
    assert b"fitness_tracker_up 1" in r.data


def test_log_entry_inserts_row(client):
    conn = MagicMock()
    conn.cursor.return_value.lastrowid = 5
    fake_mysqldb.connect.return_value = conn

    r = client.post("/log", json={"weight": 70.5, "water_liters": 2.0,
                                  "calories": 2000, "notes": "leg day"})

    assert r.status_code == 201
    assert r.get_json() == {"message": "Entry logged", "id": 5}
    args = conn.cursor.return_value.execute.call_args[0]
    assert "INSERT INTO entries" in args[0]
    assert args[1] == (70.5, 2.0, 2000, "leg day")
    conn.commit.assert_called_once()


def test_history_returns_rows(client):
    conn = MagicMock()
    conn.cursor.return_value.fetchall.return_value = [
        (1, 70.5, 2.0, 2000, "leg day", "2026-01-01 08:00:00")
    ]
    fake_mysqldb.connect.return_value = conn

    r = client.get("/history")

    assert r.status_code == 200
    body = r.get_json()
    assert body[0]["id"] == 1
    assert body[0]["calories"] == 2000
    assert body[0]["created_at"] == "2026-01-01 08:00:00"
