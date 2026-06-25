# Lambda Function Design

## Function Configuration

| Setting | Value | Reasoning |
|---|---|---|
| Function name | `users-api` | Clear, service-specific name |
| Runtime | Python 3.12 | Latest stable, boto3 included |
| Handler | `lambda_function.lambda_handler` | filename.function_name |
| Memory | 128 MB | Sufficient for DynamoDB I/O; lowest cost tier |
| Timeout | 30 seconds | DynamoDB calls rarely exceed 5s; ample buffer |
| Architecture | x86_64 | Default, ARM64 available for ~20% cost reduction |
| Execution role | `lambda-users-api-role` | Least-privilege DynamoDB access |
| Environment vars | `TABLE_NAME=users`, `REGION=us-east-1` | Avoids hardcoding |

---

## Code Structure

```
lambda_function.py
│
├── Imports + DynamoDB client init
├── DecimalEncoder class
├── build_response() helper
│
├── create_user(body)        → POST /users
├── list_users()             → GET /users
├── get_user(user_id)        → GET /users/{id}
├── update_user(user_id, body) → PUT /users/{id}
├── delete_user(user_id)     → DELETE /users/{id}
│
└── lambda_handler(event, context)  ← entry point, router
```

---

## DynamoDB Client Initialization

```python
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('users')
```

The client is initialized at **module level**, outside `lambda_handler`. This is a critical performance optimization:

- On a **cold start**, the Lambda container is created and the entire module is executed. The DynamoDB client is created once.
- On **warm invocations** (subsequent calls to the same container), `lambda_handler` is called directly — the module-level code does not re-run. The existing client is reused, saving ~20–50ms per invocation.

This pattern applies to all external clients: database connections, SDK clients, configuration loading.

---

## DecimalEncoder

```python
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)
```

DynamoDB stores numbers as `Decimal` objects (to avoid floating-point precision issues). Python's `json.dumps()` cannot serialize `Decimal` by default — it raises `TypeError`. This custom encoder converts `Decimal` to `float` before serialization.

Used in every `build_response()` call:
```python
'body': json.dumps(body, cls=DecimalEncoder)
```

---

## Routing Logic

```python
def lambda_handler(event, context):
    http_method = event.get('httpMethod', '')
    path        = event.get('path', '')
    path_params = event.get('pathParameters') or {}
    body        = event.get('body', '{}') or '{}'
```

**Why `or {}`?** API Gateway sends `pathParameters: null` (not an empty dict) when there are no path parameters. `event.get('pathParameters') or {}` handles both `None` and missing key safely.

**Why `or '{}'` for body?** GET and DELETE requests have no body. API Gateway sends `body: null`. `or '{}'` prevents `json.loads(None)` from raising `TypeError`.

Routing is sequential `if` statements — not `elif`. This is intentional: each condition is explicit and the fall-through to 404 is clear.

```python
# Specific path check before path_params check — order matters
if http_method == 'GET' and path == '/users':      # matches /users
    return list_users()

if http_method == 'GET' and 'userId' in path_params:  # matches /users/{id}
    return get_user(path_params['userId'])
```

The `/users` (collection) route is checked before the `/{userId}` (item) route to prevent `/users` being matched as a userId.

---

## Update Expression Builder

The most complex piece of code:

```python
update_expr = "SET updatedAt = :updatedAt"
expr_values = {':updatedAt': datetime.utcnow().isoformat()}
expr_names  = {}

allowed_fields = ['name', 'email', 'role']
for field in allowed_fields:
    if field in data:
        placeholder = f'#{field}'
        update_expr += f', {placeholder} = :{field}'
        expr_values[f':{field}'] = data[field]
        expr_names[placeholder]  = field
```

**Why `#name` instead of `name`?** DynamoDB has reserved words — `name` is one of them. Using expression attribute names (`#name`) avoids conflicts with DynamoDB reserved keywords. The `#` prefix signals it's an alias.

**Why only `allowed_fields`?** Whitelist approach: only fields in `['name', 'email', 'role']` can be updated. This prevents a client from overwriting `userId`, `createdAt`, or injecting arbitrary attributes.

**Dynamic expression**: If the request body contains only `{"role": "admin"}`, the expression becomes:
```
SET updatedAt = :updatedAt, #role = :role
```
Only `role` and `updatedAt` change. All other attributes are untouched — this is a true partial update, not a replace.

---

## Error Handling Pattern

Every handler function uses `try/except`:

```python
def create_user(body):
    try:
        # ... business logic
        return build_response(201, {...})
    except Exception as e:
        return build_response(500, {'error': str(e)})
```

This ensures:
- Any unhandled exception returns a 500 JSON response (not an API Gateway 502)
- The error message is visible in the response body for debugging
- CloudWatch Logs capture the full Python traceback via the exception

In production, you would log the full exception with `traceback.format_exc()` and return a generic message to the client — exposing internal error details is a security risk.

---

## Cold Start Behaviour

A cold start occurs when:
- Lambda function is invoked for the first time
- Lambda function has not been invoked recently (~15 minute idle timeout)
- Concurrency scaling forces new container creation

During a cold start:
1. AWS downloads the deployment package (~1 KB for this function)
2. Python interpreter starts
3. Module-level code executes (imports, DynamoDB client init)
4. `lambda_handler()` is called

Typical cold start duration: **100–500ms** for this function.

Warm invocation duration: **20–100ms** (DynamoDB latency dominates).

For this API, cold starts are acceptable. Production systems with strict latency requirements use Provisioned Concurrency (keeps containers pre-warmed at extra cost).

---

## Monitoring

Lambda automatically publishes to CloudWatch:

| Metric | Namespace | What it shows |
|---|---|---|
| Invocations | AWS/Lambda | Total calls |
| Errors | AWS/Lambda | Exceptions (not 4xx — those are successful invocations) |
| Duration | AWS/Lambda | Execution time in milliseconds |
| Throttles | AWS/Lambda | Requests rejected due to concurrency limits |
| ConcurrentExecutions | AWS/Lambda | Parallel Lambda containers running |

Log group: `/aws/lambda/users-api` — every invocation generates a START, END, REPORT log line plus any `print()` output.