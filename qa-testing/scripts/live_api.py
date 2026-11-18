"""
Helper gọi BACKEND THẬT cho các script kiểm thử hộp đen Epic 01 (Auth & RBAC).
Thay thế cách "mô phỏng logic bằng Python" trước đây: kết quả trong báo cáo Excel là phản hồi thật của API.

Yêu cầu: backend đang chạy (docker compose up -d). Đổi địa chỉ bằng biến môi trường API_BASE_URL.
"""
import base64
import hashlib
import hmac
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

BASE_URL = os.environ.get('API_BASE_URL', 'http://localhost:8080')
ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL', 'admin@rescue.vn')
ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'admin123')
DEFAULT_NEW_USER_PASSWORD = '123456'  # Mật khẩu mặc định backend gán khi Admin tạo user (UserService.createUser)
APP_YML = os.path.join(os.path.dirname(__file__), '..', '..', 'backend', 'src', 'main', 'resources', 'application.yml')

_admin = None


def call(method, path, body=None, token=None, raw_body=None):
    """Gửi request thật, trả về (http_code, json_body)."""
    data = raw_body if raw_body is not None else (json.dumps(body).encode('utf-8') if body is not None else None)
    req = urllib.request.Request(BASE_URL + path, data=data, method=method, headers={'Content-Type': 'application/json'})
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            text = res.read().decode('utf-8')
            return res.status, (json.loads(text) if text else {})
    except urllib.error.HTTPError as e:
        text = e.read().decode('utf-8')
        try:
            return e.code, json.loads(text)
        except ValueError:
            return e.code, {'message': text[:200]}
    except urllib.error.URLError as e:
        sys.exit(f'Không kết nối được backend tại {BASE_URL} ({e.reason}). Hãy chạy "docker compose up -d" trước.')


def message_of(body):
    return body.get('message') if isinstance(body, dict) else None


def login(email, password):
    code, body = call('POST', '/api/auth/login', {'email': email, 'password': password})
    return code, body


def admin():
    """Phiên đăng nhập Admin (token, id)."""
    global _admin
    if _admin is None:
        code, body = login(ADMIN_EMAIL, ADMIN_PASSWORD)
        if code != 200:
            sys.exit(f'Không đăng nhập được Admin {ADMIN_EMAIL}: HTTP {code} {message_of(body)}')
        _admin = body
    return _admin


def create_user(role_id='USER', prefix='qa'):
    """Admin tạo user mới (mật khẩu mặc định 123456). Trả về dict user kèm email."""
    email = f'{prefix}_{int(time.time() * 1000)}@rescue.vn'
    code, body = call('POST', '/api/v1/admin/users',
                      {'fullName': f'QA {role_id}', 'email': email, 'phone': '0912345678', 'roleId': role_id},
                      admin()['token'])
    if code != 200:
        sys.exit(f'Không tạo được user {role_id}: HTTP {code} {message_of(body)}')
    time.sleep(0.002)  # tránh trùng email theo millisecond
    return {**body['data'], 'email': email, 'password': DEFAULT_NEW_USER_PASSWORD}


def set_status(user_id, status):
    return call('PUT', f'/api/v1/admin/users/{user_id}/status?status={status}', None, admin()['token'])


def token_of(user):
    code, body = login(user['email'], user['password'])
    if code != 200:
        sys.exit(f'Không đăng nhập được {user["email"]}: HTTP {code} {message_of(body)}')
    return body['token']


def _b64url(raw):
    return base64.urlsafe_b64encode(raw).rstrip(b'=').decode()


def expired_token(email=None):
    """Token THẬT (ký đúng khóa của backend) nhưng đã hết hạn 1 giờ trước — dùng cho ca kiểm thử TOKEN EXPIRED."""
    with open(APP_YML, encoding='utf-8') as f:
        secret = re.search(r'^\s*secret:\s*["\']?([^"\'\s#]+)', f.read(), re.M).group(1)
    now = int(time.time())
    header = _b64url(json.dumps({'alg': 'HS256'}).encode())
    payload = _b64url(json.dumps({'sub': email or ADMIN_EMAIL, 'iat': now - 7200, 'exp': now - 3600}).encode())
    signing_input = f'{header}.{payload}'.encode()
    signature = hmac.new(base64.b64decode(secret), signing_input, hashlib.sha256).digest()
    return f'{header}.{payload}.{_b64url(signature)}'


def tampered_token():
    """Token Admin thật nhưng bị sửa chữ ký — dùng cho ca kiểm thử TOKEN TAMPERED."""
    token = admin()['token']
    return token[:-2] + ('AA' if not token.endswith('AA') else 'BB')
