local jwt = require "resty.jwt"
local http = require "resty.http"
local cjson = require "cjson"
local PluginLoader = require "plugin_loader"
local TenantManager = require "tenant_manager"

local config = {
    jwt_secret = os.getenv("JWT_SECRET") or "your_secret_key",
    jwt_algorithm = os.getenv("JWT_ALGO") or "HS256",
    skip_paths = "^/health$|^/login$|^/metrics$|^/admin/",
    -- TODO: implement
    validate_tenant_id = true,
    tenant_id_header_name = "X-Tenant-Id",
    validate_subdomain = true,
    validate_pathname_slug = true,
    pathname_slug_pattern = "^/api/v1/([^/]+)/",
    payload_mapping = {
        user_id = "sub",
        tenant_id = "tenant_id",
        subdomain = "subdomain",
        pathname_slugs = "pathname_slugs",
        role_ids = "role_ids"
    },
    -- flag if rbac feature is to be enabled
    rbac_enabled = true,
    -- collection role based access list
    rbac_cache_store = "redis",
    rbac_cache_store_opts = { url = "redis://localhost:6379" },
    -- cached verified paths a user has access
    user_permissions_store = "redis",
    user_permissions_cache_store_opts = { url = "redis://localhost:6379" },
    cached_permissions_ttl =  os.getenv("CACHED_PERMISSIONS_TTL") or 1800, -- default: 30 minutes
    unauthorized_response = cjson.encode({ error = "Authentication required" }),
    forbidden_response = cjson.encode({ error = "Access denied" }),
    service_discovery = {
        provider = "consul",
        consul_url = "http://localhost:8500",
        cache_ttl = 60
    },
    plugin_dir = "/plugins",
    plugin_config = "/config/plugins.json",
    log_file = "/logs/aegis.log",
    tenant_manager = {
        tenant_api_url = os.getenv("TENANT_API_URL") or "http://localhost:8080/api/v1/tenants",
        api_token = os.getenv("TENANT_API_TOKEN"),
        cache_ttl = 3600
    }
}

local plugin_loader = PluginLoader.new(config.plugin_dir, config.plugin_config)
plugin_loader:load_plugins()

local tenant_manager = TenantManager.new(config.tenant_manager)

local function is_skip_path(path)
    return ngx.re.match(path, config.skip_paths, "jo")
end

local function extract_jwt()
    local auth_header = ngx.var.http_authorization
    if not auth_header or not auth_header:match("^Bearer ") then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say(config.unauthorized_response)
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end
    return auth_header:sub(8)
end

local function validate_jwt(jwt_token)
    local jwt_obj = jwt:verify(config.jwt_secret, jwt_token)
    if not jwt_obj.verified then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say(config.unauthorized_response)
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end
    return jwt_obj.payload
end

local function validate_tenant_access(payload, request_context)
    local valid, error_msg = tenant_manager:validate_tenant_access(payload, request_context)
    if not valid then
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say(cjson.encode({ error = error_msg }))
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    return true
end

local function validate_pathname_slug(payload)
    if not config.validate_pathname_slug then
        return true
    end
    local path = ngx.var.uri
    local match = ngx.re.match(path, config.pathname_slug_pattern, "jo")
    if not match then
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say(config.forbidden_response)
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    local path_slug = match[1]
    local pathname_slugs = payload[config.payload_mapping.pathname_slugs]
    if type(pathname_slugs) ~= "table" or not table_contains(pathname_slugs, path_slug) then
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say(config.forbidden_response)
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    return true
end

local function table_contains(tbl, item)
    for _, v in ipairs(tbl) do
        if v == item then
            return true
        end
    end
    return false
end

local function check_rbac(payload)
    if not config.rbac_enabled then
        return true
    end
    local cache_key = string.format("%s:%s:%s:%s",
        payload[config.payload_mapping.user_id],
        ngx.var.host,
        ngx.var.uri,
        ngx.var.request_method
    )
    local cache = ngx.shared.rbac_cache
    local permission = cache:get(cache_key)
    ngx.ctx.cache_hit = permission ~= nil
    ngx.ctx.cache_type = "rbac"
    if permission == nil then
        local httpc = http.new()
        local res, err = httpc:request_uri(config.cache_options.url .. "/rbac", {
            method = "GET",
            query = { key = cache_key }
        })
        if not res or res.status ~= 200 then
            ngx.status = ngx.HTTP_FORBIDDEN
            ngx.say(config.forbidden_response)
            return ngx.exit(ngx.HTTP_FORBIDDEN)
        end
        permission = cjson.decode(res.body).allowed
        if config.cache_write_enabled then
            cache:set(cache_key, permission, 3600)
        end
    end
    if not permission then
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say(config.forbidden_response)
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    return true
end

local function discover_service(payload, context)
    local tenant_id = payload[config.payload_mapping.tenant_id]
    local service_name = context.request.uri:match("^/api/v1/([^/]+)") or "default"

    -- Get tenant-specific service mapping
    local service_mapping = tenant_manager:get_service_mapping(tenant_id, service_name)

    -- If tenant has custom backend, use it directly
    if service_mapping.backend_url ~= "http://127.0.0.1:8080" then
        return service_mapping.backend_url:match("http://(.+)")
    end

    -- Otherwise use Consul service discovery
    local full_service_name = "api-service-" .. tenant_id
    local cache_key = "service:" .. full_service_name
    local cache = ngx.shared.service_cache
    local backend_addr = cache:get(cache_key)
    ngx.ctx.cache_hit = ngx.ctx.cache_hit or backend_addr ~= nil
    ngx.ctx.cache_type = ngx.ctx.cache_type or "service"

    if backend_addr then
        return backend_addr
    end

    local httpc = http.new()
    local res, err = httpc:request_uri(config.service_discovery.consul_url .. "/v1/health/service/" .. full_service_name, {
        method = "GET",
        query = { passing = true }
    })

    if not res or res.status ~= 200 then
        ngx.log(ngx.ERR, "Service discovery failed: ", err)
        ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
        ngx.say(cjson.encode({ error = "Service unavailable" }))
        return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end

    local services = cjson.decode(res.body)
    if #services == 0 then
        ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
        ngx.say(cjson.encode({ error = "No healthy services found" }))
        return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    local service = services[math.random(#services)]
    backend_addr = service.Service.Address .. ":" .. service.Service.Port
    cache:set(cache_key, backend_addr, config.service_discovery.cache_ttl)
    return backend_addr
end

-- Main request processing
local context = {
    request = {
        uri = ngx.var.uri,
        method = ngx.var.request_method,
        host = ngx.var.host,
        headers = ngx.req.get_headers()
    },
    response = {},
    payload = nil,
    backend_addr = nil,
    start_time = ngx.now(),
    cache_hit = false,
    cache_type = nil,
    rate_limit_exceeded = false
}
ngx.ctx.start_time = context.start_time
ngx.ctx.cache_hit = context.cache_hit
ngx.ctx.cache_type = context.cache_type
ngx.ctx.rate_limit_exceeded = context.rate_limit_exceeded

plugin_loader:run_phase("rewrite", context)

if is_skip_path(context.request.uri) then
    return
end

local jwt_token = extract_jwt()
context.payload = validate_jwt(jwt_token)
ngx.ctx.payload = context.payload

-- Multi-tenant validation
validate_tenant_access(context.payload, context)
validate_pathname_slug(context.payload)
check_rbac(context.payload)

-- Track tenant usage
local tenant_id = context.payload[config.payload_mapping.tenant_id]
tenant_manager:increment_usage(tenant_id, "requests_per_minute", 1)

context.backend_addr = discover_service(context.payload, context)
ngx.var.backend_addr = context.backend_addr

plugin_loader:run_phase("access", context)

ngx.req.set_header("X-User-Id", context.payload[config.payload_mapping.user_id])
ngx.req.set_header("X-Company-Group-Id", context.payload[config.payload_mapping.tenant_id])

-- File-based logging
local log_entry = {
    timestamp = ngx.time(),
    user_id = context.payload[config.payload_mapping.user_id],
    tenant_id = context.payload[config.payload_mapping.tenant_id],
    uri = context.request.uri,
    method = context.request.method,
    status = context.response.status or ngx.status,
    latency_ms = (ngx.now() - context.start_time) * 1000,
    backend_addr = context.backend_addr
}
local file = io.open(config.log_file, "a")
if file then
    file:write(cjson.encode(log_entry) .. "\n")
    file:close()
end
