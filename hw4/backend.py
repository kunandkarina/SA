from flask import Flask, request, send_file, jsonify
import psycopg2
import os
import socket
from werkzeug.utils import secure_filename

app = Flask(__name__)

DB_CONFIG = {
    'dbname': 'sa-hw4',
    'user': 'root',
    'password': os.environ.get('PGPASSWORD'),
    'host': '192.168.100.1',
    'port':'5432'
}

UPLOAD_FOLDER = '/home/judge/shared/uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/ip', methods=['GET'])
def get_ip():
    forwarded_for = request.headers.get('X-Forwarded-For')
    real_ip = request.headers.get('X-Real-IP')
    remote_addr = request.remote_addr

    ip = '192.168.100.1'

    try:
        hostname = socket.gethostname()
    except socket.herror:
        hostname = 'Unknown Host'

    return jsonify({'ip': ip, 'hostname': hostname})

@app.route('/file/<file_name>', methods=['GET'])
def get_file(file_name):
    file_path = os.path.join(UPLOAD_FOLDER, secure_filename(file_name))
    if os.path.exists(file_path):
        return send_file(file_path)
    return jsonify({'error': 'File not found'}), 404

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    file_name = secure_filename(file.filename)
    file_path = os.path.join(UPLOAD_FOLDER, file_name)
    file.save(file_path)

    return jsonify({"filename": f"{file_name}", "success": "true"}), 200

@app.route('/db/<name>', methods=['GET'])
def get_user(name):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM "user" WHERE name = %s', (name,))
        user = cur.fetchone()
        cur.close()
        conn.close()

        if user is None:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({
            'id': user[0],
            'name': user[1]
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='192.168.100.1', port=8080)