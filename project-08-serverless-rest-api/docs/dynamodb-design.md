# DynamoDB Design — Users Table

## Table Configuration

| Setting | Value | Reasoning |
|---|---|---|
| Table name | `users` | Simple, lowercase, service-aligned |
| Partition key | `userId` (String) | UUID — globally unique, evenly distributed |
| Sort key | None | Single-item access pattern; no range queries needed |
| Table class | DynamoDB Standard | Default, optimized for active data |
| Billing mode | On-demand (PAY_PER_REQUEST) | No capacity planning needed; scales to zero |
| Encryption | AWS owned key | Default; sufficient for non-sensitive data |

---

## Key Design

### Why UUID for partition key?

```python
user_id = str(uuid.uuid4())
# Example: "550e8400-e29b-41d4-a716-446655440000"
```

UUID v4 provides:
- **Global uniqueness** without coordination (no auto-increment needed)
- **Even distribution** across DynamoDB partitions (random bytes = no hot partitions)
- **Opacity** — IDs cannot be enumerated by incrementing an integer

Alternative partition keys considered:
- `email` — not suitable (emails change; sequential patterns possible)
- `username` — not suitable (string patterns may hot-partition)
- Auto-increment integer — DynamoDB does not support this natively

### No sort key

A sort key enables range queries within a partition. The `users` table has one access pattern: lookup by `userId`. There is no need to query "all users created after date X" within a partition, so no sort key is needed.

If you added a secondary access pattern ("find all users with role=admin"), you would add a Global Secondary Index (GSI) — not a sort key on the primary table.

---

## Access Patterns

| Pattern | DynamoDB Operation | Used by |
|---|---|---|
| Create a user | `put_item` | POST /users |
| Get all users | `scan` | GET /users |
| Get one user | `get_item` with PK | GET /users/{id} |
| Update user fields | `update_item` with PK | PUT /users/{id} |
| Delete a user | `delete_item` with PK | DELETE /users/{id} |

### On Scan vs Query

`table.scan()` reads every item in the table. For this project with a small number of test users, this is fine. At scale (10,000+ users), a full table scan:
- Is slow (reads all partitions)
- Consumes read capacity on every item regardless of whether it matches a filter
- Returns up to 1 MB per page (requires pagination for larger tables)

Production alternatives:
- Add a GSI on `role` if "list users by role" is needed
- Use `LastEvaluatedKey` for paginated scans
- Use ElasticSearch / OpenSearch for full-text or complex queries

---

## Item Structure

```json
{
  "userId":    "550e8400-e29b-41d4-a716-446655440000",
  "name":      "Vinay Kumar",
  "email":     "vinay@example.com",
  "role":      "admin",
  "createdAt": "2025-06-01T10:30:00.123456",
  "updatedAt": "2025-06-01T10:30:00.123456"
}
```

DynamoDB attribute types used:
- `S` (String) — all attributes in this table
- No `N` (Number) or `B` (Binary) used in this project

---

## DynamoDB Operations in Code

### PutItem (create)
```python
table.put_item(Item=item)
```
Writes the complete item. If an item with the same `userId` exists, it is replaced. For create-only semantics, use a `ConditionExpression` to reject duplicates — not implemented here for simplicity.

### GetItem (read)
```python
response = table.get_item(Key={'userId': user_id})
user = response.get('Item')
```
Single-item lookup by primary key. Returns `None` if the key does not exist. This is a strongly consistent read by default.

### UpdateItem (update)
```python
response = table.update_item(
    Key={'userId': user_id},
    UpdateExpression="SET updatedAt = :updatedAt, #role = :role",
    ExpressionAttributeValues={':updatedAt': ts, ':role': 'admin'},
    ExpressionAttributeNames={'#role': 'role'},
    ReturnValues='ALL_NEW'
)
updated = response.get('Attributes', {})
```
Updates only specified attributes — all others are preserved. `ReturnValues='ALL_NEW'` returns the complete item post-update, so the API can return the updated user without a second `get_item` call.

### DeleteItem (delete)
```python
table.delete_item(Key={'userId': user_id})
```
Removes the item. Idempotent — no error if the key does not exist. The existence check before deletion is explicit in this project to enable a 404 response.

### Scan (list all)
```python
response = table.scan()
users = response.get('Items', [])
```
Returns all items. For tables with >1 MB of data, pagination is required using `LastEvaluatedKey` / `ExclusiveStartKey`.

---

## On-Demand Billing

With `PAY_PER_REQUEST` billing mode:
- No provisioned capacity to plan
- No `ProvisionedThroughputExceededException` errors
- Cost is per read/write request unit consumed

Free tier provides 25 WCU + 25 RCU per month on provisioned tables. On-demand tables have no free tier WCU/RCU — but the free tier includes 25 GB of storage and the first 200M requests/month are included in the DynamoDB free tier for on-demand tables.

For this project: cost is $0.00.

---

## Console Exploration

After running tests:

1. `DynamoDB → Tables → users → Explore table items`
2. See all users with every attribute visible
3. Click any item to see the raw attribute view
4. Use the query/filter controls to search by attribute value

CLI scan:
```powershell
aws dynamodb scan \
  --table-name users \
  --query "Items[*].{ID:userId.S,Name:name.S,Email:email.S,Role:role.S}" \
  --output table
```