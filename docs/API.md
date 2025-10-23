# API Documentation

Complete API reference for all microservices.

## Base URLs

- **Development**: `http://<load-balancer-dns>`
- **API Gateway**: Port 3000
- **Direct Service Access**: Ports 3001-3003 (internal only)

## API Gateway

### Health Endpoints

#### Get API Gateway Health
```http
GET /health
```

**Response**:
```json
{
  "status": "UP",
  "service": "api-gateway",
  "timestamp": "2025-01-15T10:30:00.000Z"
}
```

#### Get All Services Health
```http
GET /health/services
```

**Response**:
```json
{
  "status": "UP",
  "services": {
    "auth": "UP",
    "product": "UP",
    "order": "UP"
  },
  "timestamp": "2025-01-15T10:30:00.000Z"
}
```

### Service Routes

All requests are proxied through the API Gateway:

- `/api/auth/*` → Auth Service
- `/api/products/*` → Product Service
- `/api/orders/*` → Order Service

---

## Authentication Service

### Register User

```http
POST /api/auth/register
```

**Request Body**:
```json
{
  "username": "john_doe",
  "password": "secure_password",
  "email": "john@example.com",
  "role": "user"
}
```

**Response** (201 Created):
```json
{
  "message": "User registered successfully",
  "username": "john_doe"
}
```

**Error Responses**:
- `400`: Missing username or password
- `409`: User already exists

### Login

```http
POST /api/auth/login
```

**Request Body**:
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response** (200 OK):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "username": "admin",
  "role": "admin",
  "expires_in": 86400
}
```

**Error Responses**:
- `400`: Missing credentials
- `401`: Invalid credentials

### Validate Token

```http
POST /api/auth/validate
Authorization: Bearer <token>
```

**Response** (200 OK):
```json
{
  "valid": true,
  "username": "admin",
  "role": "admin"
}
```

**Error Responses**:
- `401`: Token missing, expired, or invalid

### Get User Profile

```http
GET /api/auth/profile
Authorization: Bearer <token>
```

**Response** (200 OK):
```json
{
  "username": "admin",
  "email": "admin@example.com",
  "role": "admin",
  "created_at": "2025-01-01T00:00:00.000Z"
}
```

**Error Responses**:
- `401`: Unauthorized (missing or invalid token)
- `404`: User not found

### List Users (Admin Only)

```http
GET /api/auth/users
Authorization: Bearer <admin-token>
```

**Response** (200 OK):
```json
{
  "users": [
    {
      "username": "admin",
      "email": "admin@example.com",
      "role": "admin"
    },
    {
      "username": "user1",
      "email": "user1@example.com",
      "role": "user"
    }
  ]
}
```

**Error Responses**:
- `401`: Unauthorized
- `403`: Forbidden (not admin)

---

## Product Service

### List Products

```http
GET /api/products/products
```

**Query Parameters**:
- `category` (optional): Filter by category
- `minPrice` (optional): Minimum price
- `maxPrice` (optional): Maximum price

**Example**:
```http
GET /api/products/products?category=Electronics&minPrice=500
```

**Response** (200 OK):
```json
{
  "total": 2,
  "products": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Laptop",
      "description": "High-performance laptop",
      "price": 1299.99,
      "stock": 50,
      "category": "Electronics"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Smartphone",
      "description": "Latest model smartphone",
      "price": 899.99,
      "stock": 100,
      "category": "Electronics"
    }
  ]
}
```

### Get Product by ID

```http
GET /api/products/products/{id}
```

**Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Laptop",
  "description": "High-performance laptop",
  "price": 1299.99,
  "stock": 50,
  "category": "Electronics"
}
```

**Error Responses**:
- `404`: Product not found

### Create Product

```http
POST /api/products/products
```

**Request Body**:
```json
{
  "name": "Wireless Mouse",
  "description": "Ergonomic wireless mouse",
  "price": 29.99,
  "stock": 200,
  "category": "Accessories"
}
```

**Response** (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "name": "Wireless Mouse",
  "description": "Ergonomic wireless mouse",
  "price": 29.99,
  "stock": 200,
  "category": "Accessories",
  "createdAt": "2025-01-15T10:30:00.000Z"
}
```

**Error Responses**:
- `400`: Missing required fields (name, price)

### Update Product

```http
PUT /api/products/products/{id}
```

**Request Body**:
```json
{
  "price": 24.99,
  "stock": 180
}
```

**Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "name": "Wireless Mouse",
  "description": "Ergonomic wireless mouse",
  "price": 24.99,
  "stock": 180,
  "category": "Accessories",
  "updatedAt": "2025-01-15T11:00:00.000Z"
}
```

**Error Responses**:
- `404`: Product not found

### Delete Product

```http
DELETE /api/products/products/{id}
```

**Response** (204 No Content)

**Error Responses**:
- `404`: Product not found

### Check Product Availability

```http
POST /api/products/products/{id}/check-availability
```

**Request Body**:
```json
{
  "quantity": 5
}
```

**Response** (200 OK):
```json
{
  "productId": "550e8400-e29b-41d4-a716-446655440000",
  "available": true,
  "requestedQuantity": 5,
  "currentStock": 50
}
```

**Error Responses**:
- `404`: Product not found

---

## Order Service

### List Orders

```http
GET /api/orders/orders
```

**Query Parameters**:
- `status` (optional): Filter by status
- `userId` (optional): Filter by user ID

**Example**:
```http
GET /api/orders/orders?status=pending&userId=user123
```

**Response** (200 OK):
```json
{
  "total": 1,
  "orders": [
    {
      "id": "750e8400-e29b-41d4-a716-446655440000",
      "userId": "user123",
      "items": [
        {
          "productId": "550e8400-e29b-41d4-a716-446655440000",
          "name": "Laptop",
          "price": 1299.99,
          "quantity": 1
        }
      ],
      "totalAmount": 1299.99,
      "status": "pending",
      "createdAt": "2025-01-15T10:00:00.000Z"
    }
  ]
}
```

### Get Order by ID

```http
GET /api/orders/orders/{id}
```

**Response** (200 OK):
```json
{
  "id": "750e8400-e29b-41d4-a716-446655440000",
  "userId": "user123",
  "items": [
    {
      "productId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Laptop",
      "price": 1299.99,
      "quantity": 1
    }
  ],
  "totalAmount": 1299.99,
  "status": "pending",
  "createdAt": "2025-01-15T10:00:00.000Z",
  "shippingAddress": {
    "street": "123 Main St",
    "city": "New York",
    "zipCode": "10001"
  },
  "paymentMethod": "card"
}
```

**Error Responses**:
- `404`: Order not found

### Create Order

```http
POST /api/orders/orders
```

**Request Body**:
```json
{
  "userId": "user123",
  "items": [
    {
      "productId": "550e8400-e29b-41d4-a716-446655440000",
      "quantity": 1
    },
    {
      "productId": "550e8400-e29b-41d4-a716-446655440001",
      "quantity": 2
    }
  ],
  "shippingAddress": {
    "street": "123 Main St",
    "city": "New York",
    "zipCode": "10001"
  },
  "paymentMethod": "card"
}
```

**Response** (201 Created):
```json
{
  "id": "750e8400-e29b-41d4-a716-446655440001",
  "userId": "user123",
  "items": [
    {
      "productId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Laptop",
      "price": 1299.99,
      "quantity": 1
    },
    {
      "productId": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Smartphone",
      "price": 899.99,
      "quantity": 2
    }
  ],
  "totalAmount": 3099.97,
  "status": "pending",
  "createdAt": "2025-01-15T12:00:00.000Z",
  "shippingAddress": {
    "street": "123 Main St",
    "city": "New York",
    "zipCode": "10001"
  },
  "paymentMethod": "card"
}
```

**Error Responses**:
- `400`: Missing required fields or validation errors
- `404`: Product not found
- `503`: Product service unavailable

### Update Order Status

```http
PUT /api/orders/orders/{id}
```

**Request Body**:
```json
{
  "status": "confirmed"
}
```

**Allowed Statuses**:
- `pending`
- `confirmed`
- `processing`
- `shipped`
- `delivered`
- `cancelled`

**Response** (200 OK):
```json
{
  "id": "750e8400-e29b-41d4-a716-446655440001",
  "userId": "user123",
  "items": [...],
  "totalAmount": 3099.97,
  "status": "confirmed",
  "createdAt": "2025-01-15T12:00:00.000Z",
  "updatedAt": "2025-01-15T12:30:00.000Z"
}
```

**Error Responses**:
- `400`: Invalid status
- `404`: Order not found

### Cancel Order

```http
DELETE /api/orders/orders/{id}
```

**Response** (200 OK):
```json
{
  "id": "750e8400-e29b-41d4-a716-446655440001",
  "status": "cancelled",
  "cancelledAt": "2025-01-15T13:00:00.000Z"
}
```

**Error Responses**:
- `400`: Cannot cancel shipped or delivered orders
- `404`: Order not found

### Get Order Statistics

```http
GET /api/orders/stats
```

**Response** (200 OK):
```json
{
  "totalOrders": 150,
  "totalRevenue": 125000.50,
  "statusBreakdown": {
    "pending": 10,
    "confirmed": 15,
    "processing": 20,
    "shipped": 30,
    "delivered": 70,
    "cancelled": 5
  },
  "timestamp": "2025-01-15T14:00:00.000Z"
}
```

---

## Error Responses

All services follow a consistent error response format:

```json
{
  "error": "Error message description"
}
```

### HTTP Status Codes

- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `204 No Content`: Successful deletion
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required or failed
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource already exists
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Dependent service unavailable

---

## Testing the API

### Using cURL

```bash
# Get products
curl http://<load-balancer-dns>/api/products/products

# Login
curl -X POST http://<load-balancer-dns>/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Create order with token
TOKEN="<your-jwt-token>"
curl -X POST http://<load-balancer-dns>/api/orders/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "userId": "user123",
    "items": [{"productId": "...", "quantity": 1}]
  }'
```

### Using Postman

1. Import the API collection (if available)
2. Set environment variables:
   - `BASE_URL`: Load balancer DNS
   - `TOKEN`: JWT token from login
3. Test endpoints sequentially

### Default Test Users

- **Admin**:
  - Username: `admin`
  - Password: `admin123`
  - Role: `admin`

- **User**:
  - Username: `user1`
  - Password: `password123`
  - Role: `user`
