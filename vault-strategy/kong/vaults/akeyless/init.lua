--[[
  Akeyless vault strategy for Kong Gateway Secrets Management.

  Resolves {vault://<prefix>/<secret-path>[/<json-key>]} references by calling
  the Akeyless REST API (/auth, /get-secret-value).

  JSON secrets: store {"username":"u","password":"p"} in Akeyless and reference
  {vault://akeyless-vault/kong/pg/username} — Kong extracts the key from the JSON body.
]]

local kong_meta = require "kong.meta"
local cjson = require "cjson.safe"
local http = require "resty.http"


local type = type
local concat = table.concat
local gsub = string.gsub
local sub = string.sub
local ngx = ngx
local decode_base64 = ngx.decode_base64


local AUTH_CACHE = {}


local function trim_trailing_slash(url)
  if type(url) ~= "string" or url == "" then
    return url
  end

  return (gsub(url, "/+$", ""))
end


local function join_path(prefix, resource)
  local path = resource or ""
  if prefix and prefix ~= "" then
    local p = prefix
    if sub(p, 1, 1) ~= "/" then
      p = "/" .. p
    end
    if sub(path, 1, 1) == "/" then
      path = sub(path, 2)
    end
    path = p .. "/" .. path
  elseif sub(path, 1, 1) ~= "/" then
    path = "/" .. path
  end

  path = gsub(path, "/+", "/")
  return path
end


local function read_file(path)
  if not path or path == "" then
    return nil, "file path is empty"
  end

  local f, err = io.open(path, "r")
  if not f then
    return nil, "failed to open file: " .. tostring(err)
  end

  local content = f:read("*a")
  f:close()

  if not content or content == "" then
    return nil, "file is empty: " .. path
  end

  return content:gsub("%s+$", "")
end


local function cache_key(conf)
  return trim_trailing_slash(conf.gateway_url) .. "|" .. tostring(conf.access_id or "") .. "|" .. conf.auth_method
end


local function http_request(conf, path, body)
  local client = http.new()
  client:set_timeout(conf.timeout or 10000)

  local url = trim_trailing_slash(conf.gateway_url) .. path
  local res, err = client:request_uri(url, {
    method = "POST",
    body = cjson.encode(body),
    headers = {
      ["Content-Type"] = "application/json",
      ["Accept"] = "application/json",
    },
    ssl_verify = true,
  })

  if not res then
    return nil, "akeyless request failed: " .. tostring(err)
  end

  if res.status < 200 or res.status >= 300 then
    local snippet = res.body and sub(res.body, 1, 256) or ""
    return nil, "akeyless HTTP " .. res.status .. ": " .. snippet
  end

  local decoded, decode_err = cjson.decode(res.body)
  if not decoded then
    return nil, "invalid JSON from akeyless: " .. tostring(decode_err)
  end

  return decoded
end


local function fetch_aws_cloud_id()
  local token_client = http.new()
  token_client:set_timeout(2000)
  local token_res, token_err = token_client:request_uri(
    "http://169.254.169.254/latest/api/token",
    {
      method = "PUT",
      headers = { ["X-aws-ec2-metadata-token-ttl-seconds"] = "60" },
    }
  )

  local headers = {}
  if token_res and token_res.status == 200 and token_res.body then
    headers["X-aws-ec2-metadata-token"] = token_res.body
  elseif token_err then
    return nil, "aws metadata token: " .. tostring(token_err)
  end

  local client = http.new()
  client:set_timeout(2000)
  local res, err = client:request_uri(
    "http://169.254.169.254/latest/dynamic/instance-identity/pkcs7",
    { method = "GET", headers = headers }
  )

  if not res then
    return nil, "aws metadata: " .. tostring(err)
  end

  if res.status ~= 200 or not res.body or res.body == "" then
    return nil, "aws metadata HTTP " .. tostring(res.status)
  end

  return res.body
end


local function fetch_azure_cloud_id()
  local client = http.new()
  client:set_timeout(2000)
  local res, err = client:request_uri(
    "http://169.254.169.254/metadata/identity/oauth2/token"
      .. "?api-version=2018-02-01&resource=https://vault.akeyless.io",
    {
      method = "GET",
      headers = { ["Metadata"] = "true" },
    }
  )

  if not res then
    return nil, "azure metadata: " .. tostring(err)
  end

  if res.status ~= 200 then
    return nil, "azure metadata HTTP " .. tostring(res.status)
  end

  local decoded = cjson.decode(res.body)
  if not decoded or not decoded.access_token then
    return nil, "azure metadata missing access_token"
  end

  return decoded.access_token
end


local function fetch_gcp_cloud_id(audience)
  local token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
  local jwt, err = read_file(token_path)
  if jwt then
    return jwt
  end

  local client = http.new()
  client:set_timeout(2000)
  local res, req_err = client:request_uri(
    "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity"
      .. "?audience=" .. ngx.escape_uri(audience or "akeyless.io"),
    {
      method = "GET",
      headers = { ["Metadata-Flavor"] = "Google" },
    }
  )

  if not res then
    return nil, req_err or err
  end

  if res.status ~= 200 or not res.body or res.body == "" then
    return nil, "gcp metadata HTTP " .. tostring(res.status)
  end

  return res.body
end


local function build_auth_body(conf)
  local method = conf.auth_method or "api_key"
  local body = {}

  if method == "token" then
    if not conf.token or conf.token == "" then
      return nil, "token auth requires config.token"
    end
    return { token = conf.token }, conf.token
  end

  if method == "universal_identity" then
    if not conf.uid_token or conf.uid_token == "" then
      return nil, "universal_identity auth requires config.uid_token"
    end
    body["access-type"] = "universal_identity"
    body["uid-token"] = conf.uid_token
    return body
  end

  if not conf.access_id or conf.access_id == "" then
    return nil, "access_id is required for auth_method " .. method
  end

  body["access-id"] = conf.access_id

  if method == "api_key" then
    if not conf.access_key or conf.access_key == "" then
      return nil, "api_key auth requires config.access_key"
    end
    body["access-type"] = "api_key"
    body["access-key"] = conf.access_key
    return body
  end

  if method == "kubernetes" then
    if not conf.k8s_auth_config_name or conf.k8s_auth_config_name == "" then
      return nil, "kubernetes auth requires config.k8s_auth_config_name"
    end
    local jwt, jwt_err = read_file(conf.k8s_service_account_token_file)
    if not jwt then
      return nil, jwt_err
    end
    body["access-type"] = "k8s"
    body["k8s-auth-config-name"] = conf.k8s_auth_config_name
    body["k8s-service-account-token"] = jwt
    return body
  end

  local cloud_id, cloud_err
  if method == "aws_iam" then
    cloud_id, cloud_err = fetch_aws_cloud_id()
    body["access-type"] = "aws_iam"
  elseif method == "azure_ad" then
    cloud_id, cloud_err = fetch_azure_cloud_id()
    body["access-type"] = "azure_ad"
  elseif method == "gcp" then
    cloud_id, cloud_err = fetch_gcp_cloud_id(conf.gcp_audience)
    body["access-type"] = "gcp"
    if conf.gcp_audience then
      body["gcp-audience"] = conf.gcp_audience
    end
  else
    return nil, "unsupported auth_method: " .. tostring(method)
  end

  if not cloud_id then
    return nil, cloud_err or "failed to obtain cloud identity"
  end

  body["cloud-id"] = cloud_id
  return body
end


local function authenticate(conf)
  if conf.auth_method == "token" then
    local _, token = build_auth_body(conf)
    return token
  end

  local key = cache_key(conf)
  local now = ngx.time()
  local cached = AUTH_CACHE[key]
  if cached and cached.expires_at > now then
    return cached.token
  end

  local body, err = build_auth_body(conf)
  if not body then
    return nil, err
  end

  if body.token then
    return body.token
  end

  local res, req_err = http_request(conf, "/auth", body)
  if not res then
    return nil, req_err
  end

  local token = res.token
  if type(token) ~= "string" or token == "" then
    return nil, "auth response missing token"
  end

  AUTH_CACHE[key] = {
    token = token,
    expires_at = now + 300,
  }

  return token
end


local function extract_secret_value(response, path)
  if type(response) ~= "table" then
    return nil, "unexpected response type"
  end

  local value = response[path]
  if value == nil and response[path:sub(2)] then
    value = response[path:sub(2)]
  end

  if value == nil then
    for k, v in pairs(response) do
      if type(k) == "string" and (k == path or k == path:sub(2)) then
        value = v
        break
      end
    end
  end

  if value == nil then
    local keys = {}
    for k in pairs(response) do
      keys[#keys + 1] = tostring(k)
    end
    return nil, "secret not found in response for path " .. path
      .. " (keys: " .. concat(keys, ", ") .. ")"
  end

  if type(value) == "table" then
    if value.value ~= nil then
      value = value.value
    else
      value = cjson.encode(value)
    end
  end

  if type(value) ~= "string" then
    return nil, "secret value is not a string"
  end

  return value
end


local function get(conf, resource, version)
  if version and version ~= 0 then
    return nil, "akeyless vault does not support secret version " .. tostring(version)
  end

  local token, err = authenticate(conf)
  if not token then
    return nil, err
  end

  local path = join_path(conf.path_prefix, resource)
  local res, req_err = http_request(conf, "/get-secret-value", {
    token = token,
    names = { path },
  })

  if not res then
    return nil, req_err
  end

  local value, value_err = extract_secret_value(res, path)
  if not value then
    return nil, value_err
  end

  if conf.base64_decode then
    local decoded = decode_base64(value)
    if not decoded then
      return nil, "failed to base64-decode secret at " .. path
    end
    value = decoded
  end

  local ttl = conf.ttl
  if ttl == 0 then
    ttl = nil
  end

  return value, nil, ttl
end


return {
  VERSION = kong_meta.version,
  license_required = true,
  get = get,
}
