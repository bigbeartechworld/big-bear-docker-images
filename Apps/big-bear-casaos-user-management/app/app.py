from flask import Flask, render_template, redirect, url_for, flash, request
from user_management import (list_users, add_user, edit_password, 
                           remove_user, reset_database, hash_password)
from functools import wraps
from flask import request, Response
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key'

ADMIN_USERNAME = os.environ.get('ADMIN_USERNAME', '')
ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', '')

if not ADMIN_USERNAME.strip() or not ADMIN_PASSWORD.strip():
    raise RuntimeError('Set nonempty ADMIN_USERNAME and ADMIN_PASSWORD before starting the application.')

if ':' in ADMIN_USERNAME:
    raise RuntimeError('ADMIN_USERNAME must not contain a colon.')

if ADMIN_PASSWORD in {'casaos', 'YOUR_SECURE_PASSWORD'}:
    raise RuntimeError('ADMIN_PASSWORD must replace the public example password.')

def check_auth(username, password):
    """Verify admin credentials"""
    return username == ADMIN_USERNAME and password == ADMIN_PASSWORD

def authenticate():
    return Response(
        'Could not verify your access level for that URL.\n'
        'You have to login with proper credentials', 401,
        {'WWW-Authenticate': 'Basic realm="Login Required"'}
    )

def requires_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)
    return decorated

@app.route('/')
@requires_auth
def index():
    users = list_users(return_data=True)
    return render_template('index.html', users=users)

@app.route('/add_user', methods=['POST'])
@requires_auth
def add_user_route():
    username = request.form.get('username')
    password = request.form.get('password')
    if add_user(username, password):
        flash('User added successfully', 'success')
    return redirect(url_for('index'))

@app.route('/edit_password', methods=['POST'])
@requires_auth
def edit_password_route():
    user_id = request.form.get('user_id')
    new_password = request.form.get('new_password')
    if edit_password(user_id, new_password):
        flash('Password updated successfully', 'success')
    return redirect(url_for('index'))

@app.route('/remove_user', methods=['POST'])
@requires_auth
def remove_user_route():
    user_id = request.form.get('user_id')
    if remove_user(user_id):
        flash('User removed successfully', 'success')
    return redirect(url_for('index'))

@app.route('/reset_database', methods=['POST'])
@requires_auth
def reset_database_route():
    if reset_database():
        flash('Database reset successfully', 'success')
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
