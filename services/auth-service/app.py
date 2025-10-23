from flask import Flask, request, jsonify
from flask_cors import CORS
import jwt
import bcrypt
import datetime
import os
from functools import wraps
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

# Configuration
SECRET_KEY = os.getenv('JWT_SECRET', 'your-secret-key-change-in-production')
TOKEN_EXPIRATION_HOURS = int(os.getenv('TOKEN_EXPIRATION_HOURS', 24))

# In-memory user store (replace with database in production)
users = {
    'admin': {
        'username': 'admin',
        'password': bcrypt.hashpw('admin123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
        'email': 'admin@example.com',
        'role': 'admin'
    },
    'user1': {
        'username': 'user1',
        'password': bcrypt.hashpw('password123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
        'email': 'user1@example.com',
        'role': 'user'
    }
}

def token_required(f):
    """Decorator to validate JWT tokens"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')

        if not token:
            return jsonify({'error': 'Token is missing'}), 401

        if token.startswith('Bearer '):
            token = token[7:]

        try:
            data = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            current_user = data['username']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401

        return f(current_user, *args, **kwargs)

    return decorated

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'UP',
        'service': 'auth-service',
        'timestamp': datetime.datetime.utcnow().isoformat()
    }), 200

@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        'service': 'Authentication Service',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'register': '/register',
            'login': '/login',
            'validate': '/validate',
            'profile': '/profile'
        }
    })

@app.route('/register', methods=['POST'])
def register():
    """Register a new user"""
    data = request.get_json()

    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Username and password required'}), 400

    username = data['username']

    if username in users:
        return jsonify({'error': 'User already exists'}), 409

    hashed_password = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())

    users[username] = {
        'username': username,
        'password': hashed_password.decode('utf-8'),
        'email': data.get('email', ''),
        'role': data.get('role', 'user'),
        'created_at': datetime.datetime.utcnow().isoformat()
    }

    return jsonify({
        'message': 'User registered successfully',
        'username': username
    }), 201

@app.route('/login', methods=['POST'])
def login():
    """Authenticate user and return JWT token"""
    data = request.get_json()

    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Username and password required'}), 400

    username = data['username']
    password = data['password']

    if username not in users:
        return jsonify({'error': 'Invalid credentials'}), 401

    user = users[username]

    if not bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
        return jsonify({'error': 'Invalid credentials'}), 401

    # Generate JWT token
    token = jwt.encode({
        'username': username,
        'role': user['role'],
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=TOKEN_EXPIRATION_HOURS)
    }, SECRET_KEY, algorithm='HS256')

    return jsonify({
        'token': token,
        'username': username,
        'role': user['role'],
        'expires_in': TOKEN_EXPIRATION_HOURS * 3600  # in seconds
    }), 200

@app.route('/validate', methods=['POST'])
def validate_token():
    """Validate JWT token"""
    token = request.headers.get('Authorization')

    if not token:
        return jsonify({'valid': False, 'error': 'Token missing'}), 401

    if token.startswith('Bearer '):
        token = token[7:]

    try:
        data = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return jsonify({
            'valid': True,
            'username': data['username'],
            'role': data['role']
        }), 200
    except jwt.ExpiredSignatureError:
        return jsonify({'valid': False, 'error': 'Token expired'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'valid': False, 'error': 'Invalid token'}), 401

@app.route('/profile', methods=['GET'])
@token_required
def profile(current_user):
    """Get user profile (requires authentication)"""
    if current_user not in users:
        return jsonify({'error': 'User not found'}), 404

    user = users[current_user]

    return jsonify({
        'username': user['username'],
        'email': user['email'],
        'role': user['role'],
        'created_at': user.get('created_at', '')
    }), 200

@app.route('/users', methods=['GET'])
@token_required
def list_users(current_user):
    """List all users (admin only)"""
    if users[current_user]['role'] != 'admin':
        return jsonify({'error': 'Unauthorized'}), 403

    user_list = [
        {
            'username': u['username'],
            'email': u['email'],
            'role': u['role']
        }
        for u in users.values()
    ]

    return jsonify({'users': user_list}), 200

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Route not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 3001))
    debug = os.getenv('FLASK_ENV', 'production') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)
