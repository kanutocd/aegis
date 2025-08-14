## Project folder structure

_© 2025 Kenneth C. Demanawa. All Rights Reserved._

```
 aegis/
├── core/                           # OpenResty core for API Gateway
│   ├── lib/                        # Lua scripts
│   │   ├── jwt_aegis.lua         # JWT validation, RBAC, service discovery
│   │   ├── plugin_loader.lua       # Dynamic plugin loading
│   │   ├── plugins/                # Lua plugins
│   │   │   ├── rate_limit.lua      # Rate limiting per tenant
│   │   │   ├── observability.lua   # Prometheus/Datadog metrics and logs
│   │   │   ├── webhook.lua         # Webhook notifications
│   │   │   └── custom_plugin.lua   # Template for custom plugins
│   ├── config/                     # Configuration files
│   │   ├── nginx.conf              # NGINX configuration
│   │   └── plugins.json            # Plugin configuration
│   ├── logs/                       # Log storage
│   │   └── aegis.log               # Structured JSON logs
│   └── test/                       # Lua tests
│       └── test_jwt_aegis.lua    # Unit tests for jwt_aegis
├── admin/                          # Sinatra admin API and developer portal
│   ├── lib/                        # Ruby application code
│   │   ├── aegis_admin.rb          # Sinatra app for admin API
│   │   ├── views/                  # ERB templates
│   │   │   ├── dashboard.erb       # Admin dashboard UI
│   │   │   └── docs.erb            # Developer portal
│   ├── config/                     # Sinatra configuration
│   │   └── plugins.yml             # Plugin configuration (synced with plugins.json)
│   ├── public/                     # Static assets
│   │   ├── css/                    # CSS (e.g., Tailwind)
│   │   │   └── styles.css
│   │   └── js/                     # JavaScript
│   │       └── scripts.js
│   ├── test/                       # Ruby tests
│   │   └── test_aegis_admin.rb     # Unit tests for admin API
│   ├── Gemfile                     # Ruby dependencies
│   ├── Gemfile.lock                # Locked gem versions
│   └── Dockerfile                  # Sinatra Docker image
├── docs/                           # Project documentation
│   ├── architecture.md             # Architecture overview with Mermaid diagram
│   ├── plugins.md                  # Plugin development guide
│   ├── setup.md                    # Installation and setup guide
│   └── api.md                      # API reference
├── scripts/                        # Utility scripts
│   ├── deploy.sh                   # Deployment script
│   └── sync_plugins.sh             # Sync plugins.json and plugins.yml
├── docker-compose.yml              # Docker Compose for OpenResty, Sinatra, Redis, Consul
├── .gitignore                      # Git ignore file
├── LICENSE                         # MIT License
└── README.md                       # Project overview and setup instructions

```
