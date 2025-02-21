# Based on https://github.com/carlbomsdata/casaos-user-management
# Original discussion: https://community.bigbeartechworld.com/t/casaos-user-management/2225
# Modified version by bigbeartechworld: Added UI implementation and adapted user_management.py
# to integrate with the UI while maintaining core functionality from the original.

import sqlite3
import os
import shutil
import subprocess
import hashlib
import getpass
from datetime import datetime

# Constants
DB_PATH = "/var/lib/casaos/db/user.db"
BACKUP_PATH = "/var/lib/casaos/db/user_backup.db"
SERVICE_NAME = "casaos-user-service.service"

# Helper Functions
def check_casaos_installation():
    if not os.path.exists(DB_PATH):
        return False
    service_status = subprocess.run(
        ["systemctl", "status", SERVICE_NAME],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return service_status.returncode == 0

def backup_database():
    try:
        shutil.copy(DB_PATH, BACKUP_PATH)
        return True
    except Exception:
        return False

def hash_password(password):
    """Hash the password using MD5."""
    return hashlib.md5(password.encode()).hexdigest()

def connect_db():
    """Connect to the SQLite database."""
    try:
        return sqlite3.connect(DB_PATH)
    except sqlite3.Error as e:
        print(f"Database connection error: {e}")
        exit(1)

def manage_service(action):
    """Start, stop, or restart the CasaOS user service on host OS."""
    try:
        result = subprocess.run(
            ["systemctl", "--system", action, SERVICE_NAME],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"Service {action} failed: {e.stderr}")
        return False

def list_users(return_data=False):
    """List all users in the database."""
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT id, username, role FROM o_users")
        users = cursor.fetchall()
        if return_data:
            return users
        else:
            if users:
                print("\nUsers in the database:")
                for user in users:
                    print(f"ID: {user[0]}, Username: {user[1]}, Role: {user[2]}")
            else:
                print("\nNo users found.")
    except sqlite3.Error as e:
        print(f"Error fetching users: {e}")
        return [] if return_data else None
    finally:
        conn.close()

def add_user(username, password):
    """Add a new user to the database."""
    if not username or not password:
        print("Username and password cannot be empty.")
        return False

    conn = connect_db()
    cursor = conn.cursor()
    try:
        # Check for duplicate username
        cursor.execute("SELECT 1 FROM o_users WHERE username = ?", (username,))
        if cursor.fetchone():
            print(f"Error: A user with the username '{username}' already exists.")
            return False

        hashed_password = hash_password(password)
        created_at = datetime.now().isoformat()

        # Insert the user into the database
        cursor.execute(
            "INSERT INTO o_users (username, password, role, created_at) VALUES (?, ?, ?, ?)",
            (username, hashed_password, "admin", created_at),
        )
        conn.commit()
        print(f"User '{username}' added successfully.")
        return True
    except sqlite3.Error as e:
        print(f"Error adding user: {e}")
        return False
    finally:
        conn.close()

def edit_password(user_id, new_password):
    if not user_id or not new_password:
        return False

    hashed_password = hash_password(new_password)
    updated_at = datetime.now().isoformat()

    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE o_users SET password = ?, updated_at = ? WHERE id = ?",
            (hashed_password, updated_at, user_id),
        )
        if cursor.rowcount > 0:
            conn.commit()
            return True
        return False
    except sqlite3.Error:
        return False
    finally:
        conn.close()

def remove_user(user_id):
    if not user_id:
        return False

    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM o_users WHERE id = ?", (user_id,))
        if cursor.rowcount > 0:
            conn.commit()
            return True
        return False
    except sqlite3.Error:
        return False
    finally:
        conn.close()

def reset_database():
    """Reset the database by deleting the user.db file."""
    try:
        if os.path.exists(DB_PATH):
            os.remove(DB_PATH)
            if not manage_service("restart"):
                print("Warning: Database reset successful but service restart failed")
            return True
        return False
    except Exception as e:
        print(f"Reset failed: {str(e)}")
        return False

