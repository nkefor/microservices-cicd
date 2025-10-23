const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Service URLs from environment
const SERVICES = {
  auth: process.env.AUTH_SERVICE_URL || 'http://auth-service:3001',
  product: process.env.PRODUCT_SERVICE_URL || 'http://product-service:3002',
  order: process.env.ORDER_SERVICE_URL || 'http://order-service:3003'
};

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    service: 'api-gateway',
    timestamp: new Date().toISOString()
  });
});

// Service health checks
app.get('/health/services', async (req, res) => {
  const healthChecks = await Promise.allSettled([
    axios.get(`${SERVICES.auth}/health`),
    axios.get(`${SERVICES.product}/health`),
    axios.get(`${SERVICES.order}/health`)
  ]);

  const services = {
    auth: healthChecks[0].status === 'fulfilled' ? 'UP' : 'DOWN',
    product: healthChecks[1].status === 'fulfilled' ? 'UP' : 'DOWN',
    order: healthChecks[2].status === 'fulfilled' ? 'UP' : 'DOWN'
  };

  const allUp = Object.values(services).every(status => status === 'UP');

  res.status(allUp ? 200 : 503).json({
    status: allUp ? 'UP' : 'DEGRADED',
    services,
    timestamp: new Date().toISOString()
  });
});

// Route helper function
const proxyRequest = async (req, res, serviceUrl) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${serviceUrl}${req.path}`,
      data: req.body,
      headers: {
        ...req.headers,
        host: new URL(serviceUrl).host
      },
      params: req.query
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    console.error(`Error proxying to ${serviceUrl}:`, error.message);
    res.status(error.response?.status || 500).json({
      error: error.response?.data || 'Service unavailable',
      service: serviceUrl
    });
  }
};

// Auth routes
app.all('/api/auth/*', (req, res) => {
  req.path = req.path.replace('/api/auth', '');
  proxyRequest(req, res, SERVICES.auth);
});

// Product routes
app.all('/api/products/*', (req, res) => {
  req.path = req.path.replace('/api/products', '');
  proxyRequest(req, res, SERVICES.product);
});

// Order routes
app.all('/api/orders/*', (req, res) => {
  req.path = req.path.replace('/api/orders', '');
  proxyRequest(req, res, SERVICES.order);
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'API Gateway - Microservices CI/CD Project',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      serviceHealth: '/health/services',
      auth: '/api/auth/*',
      products: '/api/products/*',
      orders: '/api/orders/*'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('Connected services:', SERVICES);
});

module.exports = app;
