# Aegis

Aegis is a multi-tenant API Gateway built on OpenResty with a Sinatra admin API. The core handles high-performance routing, while the admin provides management.

_© 2025 Kenneth C. Demanawa. All Rights Reserved._

```mermaid
graph TD
    subgraph Client[Client Requests]
        C1["Client 1 (tenant123.example.com)"] -->|HTTP/HTTPS| GW["Aegis (Multi-Tenant API Gateway OpenResty)"]
        C2["Client 2 (tenant456.example.com)"] -->|HTTP/HTTPS| GW
    end

    subgraph API_Gateway["Aegis Core OpenResty"]
        GW -->|Access Phase| JWT["JWT Validation (lua-resty-jwt)"]
        JWT -->|Payload| RBAC["RBAC Check (Redis Cache)"]
        RBAC -->|Tenant/Service| SD["Service Discovery (Consul via lua-resty-http)"]
        SD -->|Backend Address| PL["Plugin System (Plugin Loader)"]
        PL -->|Execute Plugins| P1["Rate Limiting (rate_limit.lua)"]
        PL -->|Execute Plugins| P2["Observability (observability.lua)"]
        PL -->|Execute Plugins| P3["Custom Plugins"]
    end

    subgraph Admin_Portal["Admin API & Portal Sinatra"]
        ADMIN["Admin API (/admin/*)"] -->|Manage| PL
        ADMIN -->|Metrics/Logs| OBS["Observability Data"]
        PORTAL["Developer Portal (Docs, Tutorials)"] -->|Access| ADMIN
    end

    subgraph Backend_Services["Backend Services"]
        SD -->|Routes to| BS1["Backend Service (api-service-tenant123)"]
        SD -->|Routes to| BS2["Backend Service (api-service-tenant456)"]
    end

    subgraph Observability["Observability"]
        P2 -->|Metrics| PROM["Prometheus (/metrics endpoint)"]
        P2 -->|Metrics/Logs| DD["Datadog (API Key)"]
        PROM -->|Data Source| GRAF["Grafana (Dashboards)"]
        DD -->|Data Source| GRAF
        P2 -->|Logs| LOG["File Logs (/logs/aegis.log)"]
        ADMIN -->|Expose| PROM
        ADMIN -->|Expose| LOG
    end

    subgraph Storage["Storage"]
        RBAC -->|Cache| REDIS["Redis (JWT, RBAC, Analytics)"]
        SD -->|Service Registry| CONSUL["Consul"]
        PL -->|Plugin Config| CONFIG["Config File (/config/plugins.json)"]
        ADMIN -->|Update| CONFIG
    end

    subgraph Webhooks["Webhooks"]
        P2 -->|Events| WH["Webhook Endpoints"]
        WH -->|Link| LINK["http://webhook.example.com"]
    end

    GW -->|Proxy| BS1
    GW -->|Proxy| BS2
    C1 -->|Manage| ADMIN
    C2 -->|Manage| ADMIN


```
