from flask import Flask, request, jsonify
from flask_cors import CORS
import datetime
import os
import uuid
import requests
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

# Configuration
PRODUCT_SERVICE_URL = os.getenv('PRODUCT_SERVICE_URL', 'http://product-service:3002')

# In-memory order store (replace with database in production)
orders = []

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'UP',
        'service': 'order-service',
        'timestamp': datetime.datetime.utcnow().isoformat()
    }), 200

@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        'service': 'Order Service',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'orders': '/orders',
            'orderById': '/orders/:id'
        }
    })

@app.route('/orders', methods=['GET'])
def get_orders():
    """Get all orders"""
    status = request.args.get('status')
    user_id = request.args.get('userId')

    filtered_orders = orders

    if status:
        filtered_orders = [o for o in filtered_orders if o['status'] == status]

    if user_id:
        filtered_orders = [o for o in filtered_orders if o['userId'] == user_id]

    return jsonify({
        'total': len(filtered_orders),
        'orders': filtered_orders
    }), 200

@app.route('/orders/<order_id>', methods=['GET'])
def get_order(order_id):
    """Get order by ID"""
    order = next((o for o in orders if o['id'] == order_id), None)

    if not order:
        return jsonify({'error': 'Order not found'}), 404

    return jsonify(order), 200

@app.route('/orders', methods=['POST'])
def create_order():
    """Create a new order"""
    data = request.get_json()

    if not data or not data.get('userId') or not data.get('items'):
        return jsonify({'error': 'userId and items are required'}), 400

    # Validate items and check product availability
    items = data['items']
    total_amount = 0

    for item in items:
        product_id = item.get('productId')
        quantity = item.get('quantity', 1)

        if not product_id:
            return jsonify({'error': 'productId required for all items'}), 400

        # Check product availability
        try:
            response = requests.post(
                f"{PRODUCT_SERVICE_URL}/products/{product_id}/check-availability",
                json={'quantity': quantity},
                timeout=5
            )

            if response.status_code == 404:
                return jsonify({'error': f'Product {product_id} not found'}), 404

            availability = response.json()

            if not availability.get('available'):
                return jsonify({
                    'error': f'Product {product_id} not available',
                    'requested': quantity,
                    'available': availability.get('currentStock', 0)
                }), 400

            # Get product details for price calculation
            product_response = requests.get(
                f"{PRODUCT_SERVICE_URL}/products/{product_id}",
                timeout=5
            )

            if product_response.status_code == 200:
                product = product_response.json()
                item['price'] = product['price']
                item['name'] = product['name']
                total_amount += product['price'] * quantity

        except requests.exceptions.RequestException as e:
            return jsonify({'error': 'Failed to validate products', 'details': str(e)}), 503

    # Create order
    new_order = {
        'id': str(uuid.uuid4()),
        'userId': data['userId'],
        'items': items,
        'totalAmount': round(total_amount, 2),
        'status': 'pending',
        'createdAt': datetime.datetime.utcnow().isoformat(),
        'shippingAddress': data.get('shippingAddress', {}),
        'paymentMethod': data.get('paymentMethod', 'card')
    }

    orders.append(new_order)

    return jsonify(new_order), 201

@app.route('/orders/<order_id>', methods=['PUT'])
def update_order(order_id):
    """Update order status"""
    order = next((o for o in orders if o['id'] == order_id), None)

    if not order:
        return jsonify({'error': 'Order not found'}), 404

    data = request.get_json()

    allowed_statuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled']
    new_status = data.get('status')

    if new_status and new_status not in allowed_statuses:
        return jsonify({'error': f'Invalid status. Allowed: {allowed_statuses}'}), 400

    if new_status:
        order['status'] = new_status
        order['updatedAt'] = datetime.datetime.utcnow().isoformat()

    return jsonify(order), 200

@app.route('/orders/<order_id>', methods=['DELETE'])
def cancel_order(order_id):
    """Cancel an order"""
    order = next((o for o in orders if o['id'] == order_id), None)

    if not order:
        return jsonify({'error': 'Order not found'}), 404

    if order['status'] in ['shipped', 'delivered']:
        return jsonify({'error': 'Cannot cancel shipped or delivered orders'}), 400

    order['status'] = 'cancelled'
    order['cancelledAt'] = datetime.datetime.utcnow().isoformat()

    return jsonify(order), 200

@app.route('/orders/stats', methods=['GET'])
def order_stats():
    """Get order statistics"""
    total_orders = len(orders)
    total_revenue = sum(o['totalAmount'] for o in orders if o['status'] not in ['cancelled'])

    status_counts = {}
    for order in orders:
        status = order['status']
        status_counts[status] = status_counts.get(status, 0) + 1

    return jsonify({
        'totalOrders': total_orders,
        'totalRevenue': round(total_revenue, 2),
        'statusBreakdown': status_counts,
        'timestamp': datetime.datetime.utcnow().isoformat()
    }), 200

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Route not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 3003))
    debug = os.getenv('FLASK_ENV', 'production') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)
