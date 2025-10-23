const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// In-memory product store (replace with database in production)
let products = [
  {
    id: uuidv4(),
    name: 'Laptop',
    description: 'High-performance laptop',
    price: 1299.99,
    stock: 50,
    category: 'Electronics'
  },
  {
    id: uuidv4(),
    name: 'Smartphone',
    description: 'Latest model smartphone',
    price: 899.99,
    stock: 100,
    category: 'Electronics'
  },
  {
    id: uuidv4(),
    name: 'Headphones',
    description: 'Wireless noise-cancelling headphones',
    price: 249.99,
    stock: 75,
    category: 'Accessories'
  }
];

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    service: 'product-service',
    timestamp: new Date().toISOString()
  });
});

// Get all products
app.get('/products', (req, res) => {
  const { category, minPrice, maxPrice } = req.query;

  let filtered = [...products];

  if (category) {
    filtered = filtered.filter(p => p.category.toLowerCase() === category.toLowerCase());
  }

  if (minPrice) {
    filtered = filtered.filter(p => p.price >= parseFloat(minPrice));
  }

  if (maxPrice) {
    filtered = filtered.filter(p => p.price <= parseFloat(maxPrice));
  }

  res.json({
    total: filtered.length,
    products: filtered
  });
});

// Get product by ID
app.get('/products/:id', (req, res) => {
  const product = products.find(p => p.id === req.params.id);

  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }

  res.json(product);
});

// Create new product
app.post('/products', (req, res) => {
  const { name, description, price, stock, category } = req.body;

  if (!name || !price) {
    return res.status(400).json({ error: 'Name and price are required' });
  }

  const newProduct = {
    id: uuidv4(),
    name,
    description: description || '',
    price: parseFloat(price),
    stock: parseInt(stock) || 0,
    category: category || 'Uncategorized',
    createdAt: new Date().toISOString()
  };

  products.push(newProduct);
  res.status(201).json(newProduct);
});

// Update product
app.put('/products/:id', (req, res) => {
  const index = products.findIndex(p => p.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({ error: 'Product not found' });
  }

  const updated = {
    ...products[index],
    ...req.body,
    id: products[index].id, // Prevent ID change
    updatedAt: new Date().toISOString()
  };

  products[index] = updated;
  res.json(updated);
});

// Delete product
app.delete('/products/:id', (req, res) => {
  const index = products.findIndex(p => p.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({ error: 'Product not found' });
  }

  products.splice(index, 1);
  res.status(204).send();
});

// Check product availability
app.post('/products/:id/check-availability', (req, res) => {
  const { quantity } = req.body;
  const product = products.find(p => p.id === req.params.id);

  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }

  const available = product.stock >= (quantity || 1);

  res.json({
    productId: product.id,
    available,
    requestedQuantity: quantity || 1,
    currentStock: product.stock
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Product Service',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      products: '/products',
      productById: '/products/:id'
    }
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Product Service running on port ${PORT}`);
  console.log(`Total products: ${products.length}`);
});

module.exports = app;
