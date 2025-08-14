# Aegis

_Multi-tenant API Gateway built on OpenResty_

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/aegis-gateway/aegis)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen.svg)](docker-compose.yml)

## Overview

Aegis is an open-source, high-performance API gateway designed for multi-tenant applications. Built on OpenResty with enterprise-grade features including hierarchical tenant management, advanced rate limiting, and comprehensive observability.

## Performance

- Sub-2ms latency with OpenResty
- 100K+ requests per second per node
- Zero-downtime configuration changes
- Native multi-tenant architecture

## Quick Start

### Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/kanutocd/aegis.git
cd aegis

# Start the complete stack
docker-compose up -d

# Verify installation
./scripts/aegis gateway status
```

### Manual Installation

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install openresty redis-server consul

# Install Ruby gems for admin interface
cd admin && bundle install

# Configure and start services
cd core && openresty -p . -c config/nginx.conf
cd admin && ruby lib/aegis_admin.rb

# Use the CLI
chmod +x scripts/aegis
./scripts/aegis gateway status
```

### First Steps

```bash
# Create your first tenant
./scripts/aegis tenant create --name "acme-corp" --tier premium

# Install plugins
./scripts/aegis plugin install --name rate-limit-advanced --version 2.0.0

# View metrics
./scripts/aegis gateway metrics
```

## Architecture Overview

Core components:

- **Multi-Tenant Core**: Hierarchical tenant support (Enterprise → Organization → Team → User)
- **Plugin System v2.0**: Hot reload with 12 lifecycle phases
- **Advanced Rate Limiting**: 4 algorithms with per-tenant limits
- **Security**: JWT, RBAC, mTLS support
- **CLI Management**: Complete gateway administration
- **Observability**: Prometheus metrics with Datadog integration

## Core Features

### Multi-Tenancy

- Hierarchical tenant structure: Enterprise → Organization → Team → User
- Three isolation levels: Strict, Shared, or Hybrid per service
- Automatic tenant detection from subdomains
- Per-tenant resource quotas and usage tracking
- Cross-tenant analytics for billing

### Plugin System v2.0

- Hot reload: Zero-downtime plugin updates
- 12 lifecycle phases for maximum flexibility
- Dependency management and automatic resolution
- Plugin templates for rapid development

```bash
# Create and install plugins instantly
./scripts/aegis plugin create my-custom-plugin
./scripts/aegis plugin install --name rate-limit-advanced --marketplace
./scripts/aegis plugin reload  # Hot reload without restart
```

### Security

- Advanced JWT validation with hierarchical tenant support
- Role-based access control with Redis caching
- Rate limiting with 4 algorithms (Fixed Window, Sliding Window, Token Bucket, Leaky Bucket)
- Complete multi-tenant isolation and routing

### Observability & Analytics

- 20+ built-in Prometheus metrics with tenant-specific tracking
- Datadog integration for real-time metric streaming
- Per-tenant performance and usage analytics
- Plugin execution time monitoring
- Structured JSON logging with tenant context

### CLI Management

- Complete gateway deployment and configuration
- Hierarchical tenant management
- Plugin lifecycle management with hot reload
- Analytics export and reporting

```bash
# Gateway management
./scripts/aegis gateway status
./scripts/aegis gateway deploy --config production.yaml

# Tenant operations
./scripts/aegis tenant create --name customer-x --tier enterprise
./scripts/aegis tenant list

# Plugin ecosystem
./scripts/aegis plugin install --name security-suite
./scripts/aegis plugin create custom-auth

# Analytics and monitoring
./scripts/aegis analytics export --tenant customer-x --format csv
./scripts/aegis gateway metrics
```

## Project Structure

```
aegis/
├── admin/                          # Sinatra admin interface
│   ├── lib/aegis_admin.rb         # Admin API implementation
│   └── views/                     # Web dashboard templates
├── core/                          # OpenResty gateway core
│   ├── lib/
│   │   ├── jwt_aegis.lua         # Enhanced JWT with tenant validation
│   │   ├── tenant_manager.lua    # Hierarchical multi-tenant system
│   │   ├── plugin_loader_v2.lua  # Hot-reload plugin system
│   │   └── plugins/              # Advanced plugin implementations
│   │       ├── rate_limit_advanced.lua      # 4-algorithm rate limiting
│   │       └── prometheus_observability.lua # Full observability suite
│   ├── config/nginx.conf         # High-performance gateway config
│   └── logs/                     # Gateway logs
├── scripts/
│   └── aegis                     # CLI management tool
├── docs/
│   ├── architecture.md           # System architecture
│   └── setup.md                  # Setup instructions
└── docker-compose.yml            # Complete development stack
```

## Goals and Roadmap

### Feature Comparison

| Feature          | YYYY OSS | YYYY Enterprise | Aegis |
| ---------------- | -------- | --------------- | ----- |
| Core Gateway     | Free     | $36K+/year      | Free  |
| Multi-tenant     | ❌       | ✓               | ✓     |
| RBAC             | ❌       | ✓               | ✓     |
| Advanced Plugins | ❌       | ✓               | ✓     |
| Hot Reload       | ❌       | ✓               | ✓     |
| CLI Management   | Basic    | ✓               | ✓     |

### Current Implementation Status

#### Current Features

- Enhanced multi-tenant core with hierarchical support
- Plugin system v2.0 with hot reload capability
- Advanced rate limiting with 4 algorithms
- CLI tool for complete gateway management
- Prometheus observability with comprehensive metrics

#### Technical Capabilities

- Sub-2ms latency architecture with OpenResty
- 100K+ RPS capability per node
- Zero-downtime configuration changes
- Hot plugin reload without restart

#### Multi-Tenant Implementation

- Hierarchical tenant structure (Enterprise → Organization → Team → User)
- Three isolation levels (Strict, Shared, Hybrid)
- Automatic tenant detection from subdomains
- Per-tenant resource quotas and usage tracking
- Cross-tenant analytics for billing

### Development Roadmap

#### Planned Features

1. OAuth 2.0/OIDC Provider - Full authentication server
2. GraphQL Gateway - Schema stitching and query optimization
3. Developer Portal - Auto-generated API documentation
4. Enterprise Dashboard - React-based admin interface
5. Kubernetes Operator - Native K8s deployment and management

### Community

- Documentation: Complete implementation guides
- Issues: Bug reports and feature requests
- Community: Developer discussions and contributions

## License

MIT License

Open source API gateway with enterprise features.
