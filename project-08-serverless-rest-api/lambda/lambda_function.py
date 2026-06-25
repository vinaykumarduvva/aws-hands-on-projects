import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal
from boto3.dynamodb.conditions import Key

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
table = dynamodb.Table('users')


# ── Helper: convert Decimal to float for JSON serialization ──────────
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


def build_response(status_code, body):
    """Build a standard API Gateway response."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }


# ── CREATE USER ───────────────────────────────────────────────────────
def create_user(body):
    """POST /users — create a new user."""
    try:
        data = json.loads(body) if isinstance(body, str) else body

        # Validate required fields
        if 'name' not in data or 'email' not in data:
            return build_response(400, {
                'error': 'Missing required fields: name and email'
            })

        user_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()

        item = {
            'userId':    user_id,
            'name':      data['name'],
            'email':     data['email'],
            'role':      data.get('role', 'user'),
            'createdAt': timestamp,
            'updatedAt': timestamp
        }

        table.put_item(Item=item)

        return build_response(201, {
            'message': 'User created successfully',
            'user': item
        })

    except Exception as e:
        return build_response(500, {'error': str(e)})


# ── GET ALL USERS ─────────────────────────────────────────────────────
def list_users():
    """GET /users — return all users."""
    try:
        response = table.scan()
        users = response.get('Items', [])

        return build_response(200, {
            'message': f'Found {len(users)} users',
            'count': len(users),
            'users': users
        })

    except Exception as e:
        return build_response(500, {'error': str(e)})


# ── GET SINGLE USER ───────────────────────────────────────────────────
def get_user(user_id):
    """GET /users/{id} — return a single user."""
    try:
        response = table.get_item(Key={'userId': user_id})
        user = response.get('Item')

        if not user:
            return build_response(404, {
                'error': f'User {user_id} not found'
            })

        return build_response(200, {'user': user})

    except Exception as e:
        return build_response(500, {'error': str(e)})


# ── UPDATE USER ───────────────────────────────────────────────────────
def update_user(user_id, body):
    """PUT /users/{id} — update a user's attributes."""
    try:
        data = json.loads(body) if isinstance(body, str) else body

        # Check user exists
        existing = table.get_item(Key={'userId': user_id}).get('Item')
        if not existing:
            return build_response(404, {
                'error': f'User {user_id} not found'
            })

        # Build update expression dynamically
        update_expr  = "SET updatedAt = :updatedAt"
        expr_values  = {':updatedAt': datetime.utcnow().isoformat()}
        expr_names   = {}

        allowed_fields = ['name', 'email', 'role']
        for field in allowed_fields:
            if field in data:
                placeholder = f'#{field}'
                update_expr += f', {placeholder} = :{field}'
                expr_values[f':{field}'] = data[field]
                expr_names[placeholder]  = field

        kwargs = {
            'Key': {'userId': user_id},
            'UpdateExpression': update_expr,
            'ExpressionAttributeValues': expr_values,
            'ReturnValues': 'ALL_NEW'
        }
        if expr_names:
            kwargs['ExpressionAttributeNames'] = expr_names

        response = table.update_item(**kwargs)
        updated  = response.get('Attributes', {})

        return build_response(200, {
            'message': 'User updated successfully',
            'user': updated
        })

    except Exception as e:
        return build_response(500, {'error': str(e)})


# ── DELETE USER ───────────────────────────────────────────────────────
def delete_user(user_id):
    """DELETE /users/{id} — remove a user."""
    try:
        existing = table.get_item(Key={'userId': user_id}).get('Item')
        if not existing:
            return build_response(404, {
                'error': f'User {user_id} not found'
            })

        table.delete_item(Key={'userId': user_id})

        return build_response(200, {
            'message': f'User {user_id} deleted successfully'
        })

    except Exception as e:
        return build_response(500, {'error': str(e)})


# ── MAIN HANDLER ──────────────────────────────────────────────────────
def lambda_handler(event, context):
    """
    Main entry point for all API Gateway requests.
    Routes requests based on HTTP method and path.
    """
    print(f"Event: {json.dumps(event)}")

    http_method = event.get('httpMethod', '')
    path        = event.get('path', '')
    path_params = event.get('pathParameters') or {}
    body        = event.get('body', '{}') or '{}'

    # ── Route: OPTIONS (CORS preflight) ──────────────────────────────
    if http_method == 'OPTIONS':
        return build_response(200, {'message': 'CORS OK'})

    # ── Route: POST /users ────────────────────────────────────────────
    if http_method == 'POST' and path == '/users':
        return create_user(body)

    # ── Route: GET /users ─────────────────────────────────────────────
    if http_method == 'GET' and path == '/users':
        return list_users()

    # ── Route: GET /users/{userId} ────────────────────────────────────
    if http_method == 'GET' and 'userId' in path_params:
        return get_user(path_params['userId'])

    # ── Route: PUT /users/{userId} ────────────────────────────────────
    if http_method == 'PUT' and 'userId' in path_params:
        return update_user(path_params['userId'], body)

    # ── Route: DELETE /users/{userId} ────────────────────────────────
    if http_method == 'DELETE' and 'userId' in path_params:
        return delete_user(path_params['userId'])

    # ── Route: not found ──────────────────────────────────────────────
    return build_response(404, {
        'error': f'Route not found: {http_method} {path}'
    })