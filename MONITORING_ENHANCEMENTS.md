# Monitoring Enhancements Implementation

## ✅ Completed Changes

### 1. API Gateway - Prometheus Metrics ✅

**Added**:
- ✅ Prometheus client library (`prom-client`)
- ✅ HTTP request duration histogram
- ✅ HTTP request counter
- ✅ Proxy request duration histogram
- ✅ `/metrics` endpoint
- ✅ Middleware for automatic metric collection

**Metrics Exposed**:
```
# Default Node.js metrics
nodejs_version_info
nodejs_heap_size_total_bytes
nodejs_heap_size_used_bytes
nodejs_external_memory_bytes
process_cpu_user_seconds_total
process_cpu_system_seconds_total

# Custom HTTP metrics
http_request_duration_seconds{method,route,status_code}
http_requests_total{method,route,status_code}
proxy_request_duration_seconds{target_service,status_code}
```

**Test**:
```bash
curl http://localhost:3000/metrics
```

---

## 🔧 Additional Changes Needed

### 2. Product Service - Add Metrics

Similar to API Gateway, add:
```javascript
const promClient = require('prom-client');

// Business metrics
const productsViewed = new promClient.Counter({
  name: 'products_viewed_total',
  help: 'Total number of products viewed',
  labelNames: ['product_id']
});

const productsCreated = new promClient.Counter({
  name: 'products_created_total',
  help: 'Total number of products created'
});

const productStockLevel = new promClient.Gauge({
  name: 'product_stock_level',
  help: 'Current stock level of products',
  labelNames: ['product_id', 'product_name']
});
```

### 3. Auth Service (Python) - Add Metrics

```python
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
from flask import Response

# Metrics
login_attempts = Counter('login_attempts_total', 'Total login attempts', ['status'])
registration_count = Counter('registrations_total', 'Total registrations')
token_validations = Counter('token_validations_total', 'Token validations', ['result'])
request_duration = Histogram('http_request_duration_seconds', 'Request duration', ['method', 'endpoint'])

@app.route('/metrics')
def metrics():
    return Response(generate_latest(REGISTRY), mimetype='text/plain')

# Usage in login endpoint
@app.route('/login', methods=['POST'])
def login():
    start_time = time.time()
    try:
        # ... login logic ...
        login_attempts.labels(status='success').inc()
    except:
        login_attempts.labels(status='failure').inc()
    finally:
        request_duration.labels(method='POST', endpoint='/login').observe(time.time() - start_time)
```

### 4. Order Service (Python) - Add Business Metrics

```python
from prometheus_client import Counter, Gauge, Histogram

# Business metrics
orders_created = Counter('orders_created_total', 'Total orders created')
orders_failed = Counter('orders_failed_total', 'Failed orders', ['reason'])
orders_total = Counter('orders_total', 'All order attempts')
order_value = Histogram('order_value_dollars', 'Order value in dollars', buckets=[10, 50, 100, 500, 1000, 5000])
active_orders = Gauge('active_orders', 'Currently active orders', ['status'])

# Usage
@app.route('/orders', methods=['POST'])
def create_order():
    orders_total.inc()
    try:
        # ... create order ...
        orders_created.inc()
        order_value.observe(total_amount)
        active_orders.labels(status='pending').inc()
    except Exception as e:
        orders_failed.labels(reason=str(type(e).__name__)).inc()
```

---

## 📊 Pre-Built Grafana Dashboards

### Dashboard 1: Infrastructure Overview

**Panels**:
1. **Total Servers**: `count(up{job="node-exporter"})`
2. **CPU Usage**: `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
3. **Memory Usage**: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
4. **Disk Usage**: `100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)`
5. **Network Traffic**: `rate(node_network_receive_bytes_total[5m])`

### Dashboard 2: Service Health

**Panels**:
1. **Request Rate**: `rate(http_requests_total[1m])`
2. **Error Rate**: `rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100`
3. **Response Time (p95)**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
4. **Service Uptime**: `up{job=~"api-gateway|auth-service|product-service|order-service"}`

### Dashboard 3: Business Metrics

**Panels**:
1. **Orders Per Hour**: `rate(orders_created_total[1h]) * 3600`
2. **Revenue**: `sum(rate(order_value_dollars_sum[1h])) * 3600`
3. **Active Users**: `sum(rate(login_attempts_total{status="success"}[5m]))`
4. **Product Views**: `rate(products_viewed_total[5m])`
5. **Conversion Rate**: `(rate(orders_created_total[1h]) / rate(products_viewed_total[1h])) * 100`

### Dashboard 4: Container Metrics

**Panels**:
1. **Container CPU**: `rate(container_cpu_usage_seconds_total[5m]) * 100`
2. **Container Memory**: `container_memory_usage_bytes / container_spec_memory_limit_bytes * 100`
3. **Container Network**: `rate(container_network_receive_bytes_total[5m])`
4. **Container Restarts**: `changes(container_last_seen[5m])`

---

## 🔔 Alerting Integration

### Slack Integration

**alertmanager.yml**:
```yaml
receivers:
  - name: 'slack-critical'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts-critical'
        title: '🚨 Critical Alert'
        text: |
          *Alert:* {{ .GroupLabels.alertname }}
          *Severity:* {{ .CommonLabels.severity }}
          *Summary:* {{ .CommonAnnotations.summary }}
          *Description:* {{ .CommonAnnotations.description }}
        send_resolved: true
```

### Discord Integration

```yaml
receivers:
  - name: 'discord-alerts'
    webhook_configs:
      - url: 'https://discord.com/api/webhooks/YOUR/WEBHOOK'
        send_resolved: true
```

### Email Notifications

```yaml
receivers:
  - name: 'email-ops'
    email_configs:
      - to: 'ops-team@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'alertmanager@example.com'
        auth_password: 'your-app-password'
        headers:
          Subject: '[{{ .Status }}] {{ .GroupLabels.alertname }}'
```

---

## 🎯 Jaeger Tracing Integration

### Node.js Services

**Install**:
```bash
npm install jaeger-client
```

**Code**:
```javascript
const initJaeger = require('jaeger-client').initTracer;

const config = {
  serviceName: 'api-gateway',
  sampler: {
    type: 'const',
    param: 1,
  },
  reporter: {
    agentHost: process.env.JAEGER_AGENT_HOST || 'jaeger',
    agentPort: 6832,
  },
};

const tracer = initJaeger(config);

// Middleware
app.use((req, res, next) => {
  const span = tracer.startSpan(`${req.method} ${req.path}`);
  req.span = span;
  res.on('finish', () => {
    span.setTag('http.status_code', res.statusCode);
    span.finish();
  });
  next();
});
```

### Python Services

**Install**:
```bash
pip install jaeger-client opentracing-instrumentation
```

**Code**:
```python
from jaeger_client import Config

config = Config(
    config={
        'sampler': {'type': 'const', 'param': 1},
        'logging': True,
    },
    service_name='auth-service',
)
tracer = config.initialize_tracer()

# Decorator for tracing
from functools import wraps

def trace_function(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        with tracer.start_span(f.__name__):
            return f(*args, **kwargs)
    return wrapper

@app.route('/login', methods=['POST'])
@trace_function
def login():
    # ... login logic ...
```

---

## 🔗 Updated Docker Compose

### Connect Services to Monitoring Network

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  api-gateway:
    # ... existing config ...
    networks:
      - microservices-network
      - monitoring-network
    environment:
      - JAEGER_AGENT_HOST=jaeger

  # Repeat for all services...

networks:
  microservices-network:
    driver: bridge
  monitoring-network:
    external: true
    name: monitoring-network
```

---

## 📈 CloudWatch Integration

### Terraform Module

```hcl
# infrastructure/terraform/modules/cloudwatch/main.tf

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", {stat = "Average"}],
            [".", "NetworkIn"],
            [".", "NetworkOut"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Logs"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

---

## 🚀 Quick Implementation Steps

### Step 1: Update All Services (15 min)
```bash
# Node.js services
cd services/api-gateway && npm install prom-client jaeger-client
cd services/product-service && npm install prom-client jaeger-client

# Python services
cd services/auth-service && pip install prometheus-client jaeger-client
cd services/order-service && pip install prometheus-client jaeger-client
```

### Step 2: Import Grafana Dashboards (5 min)
```bash
# Copy dashboard JSON files to grafana/dashboards/
# Grafana auto-loads them on startup
```

### Step 3: Configure Alerts (10 min)
```bash
# Update alertmanager.yml with Slack/Discord webhooks
# Restart Alertmanager
docker-compose -f monitoring/docker-compose.monitoring.yml restart alertmanager
```

### Step 4: Test Everything (10 min)
```bash
# Start all services
docker-compose up -d

# Generate traffic
for i in {1..100}; do curl http://localhost:3000/api/products/products; done

# Check metrics
curl http://localhost:3000/metrics

# View in Grafana
open http://localhost:3300
```

---

## 📊 Expected Results

After full implementation:

**Prometheus** will show:
- ✅ 50+ metrics per service
- ✅ System metrics from all servers
- ✅ Container metrics
- ✅ Custom business metrics

**Grafana** will display:
- ✅ 4-6 comprehensive dashboards
- ✅ Real-time service health
- ✅ Business KPIs
- ✅ Infrastructure status

**Jaeger** will trace:
- ✅ Request flows across services
- ✅ Latency breakdowns
- ✅ Error tracking
- ✅ Service dependencies

**Alertmanager** will notify:
- ✅ Critical issues immediately
- ✅ Warnings to team channel
- ✅ Resolved alerts

---

## 🎯 Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| API Gateway Metrics | ✅ Complete | Prometheus integrated |
| Product Service Metrics | ⏳ Code ready | Need to apply |
| Auth Service Metrics | ⏳ Code ready | Need to apply |
| Order Service Metrics | ⏳ Code ready | Need to apply |
| Grafana Dashboards | ⏳ JSON ready | Need to create files |
| Jaeger Tracing | ⏳ Config ready | Need to apply |
| Slack Alerts | ⏳ Template ready | Need webhook |
| CloudWatch Module | ⏳ Code ready | Need to apply |
| Docker Network | ⏳ Config ready | Need to update |

---

**Next**: Would you like me to implement all remaining items (Product/Auth/Order metrics, dashboards, tracing, etc.)?
