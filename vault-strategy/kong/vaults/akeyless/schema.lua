--[[
  Akeyless vault configuration schema for Kong Gateway.

  Install this module as kong.vaults.akeyless.schema (see luarocks/ rockspec).
]]

local typedefs = require "kong.db.schema.typedefs"


return {
  name = "akeyless",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            gateway_url = {
              type = "string",
              required = true,
              description = "Akeyless API or Gateway URL (e.g. https://api.akeyless.io or https://gateway.example.com/api/v2).",
            },
          },
          {
            auth_method = {
              type = "string",
              required = true,
              default = "api_key",
              one_of = { "api_key", "token", "kubernetes", "aws_iam", "azure_ad", "gcp", "universal_identity" },
              description = "Authentication method for the Akeyless API.",
            },
          },
          {
            access_id = {
              type = "string",
              description = "Akeyless Access ID (required for all auth methods except token and universal_identity).",
            },
          },
          {
            access_key = {
              type = "string",
              encrypted = true,
              description = "Akeyless Access Key (api_key auth).",
            },
          },
          {
            token = {
              type = "string",
              encrypted = true,
              description = "Pre-authenticated Akeyless token (token auth). Skips /auth.",
            },
          },
          {
            uid_token = {
              type = "string",
              encrypted = true,
              description = "Universal Identity token (universal_identity auth).",
            },
          },
          {
            k8s_auth_config_name = {
              type = "string",
              description = "Kubernetes auth config name in Akeyless (kubernetes auth).",
            },
          },
          {
            k8s_service_account_token_file = {
              type = "string",
              default = "/var/run/secrets/kubernetes.io/serviceaccount/token",
              description = "Path to the Kubernetes service account JWT (kubernetes auth).",
            },
          },
          {
            gcp_audience = {
              type = "string",
              default = "akeyless.io",
              description = "GCP audience for JWT auth (gcp auth).",
            },
          },
          {
            path_prefix = {
              type = "string",
              match = [[^/]],
              description = "Optional path prefix prepended to every secret resource (e.g. /kong).",
            },
          },
          {
            timeout = {
              type = "integer",
              default = 10000,
              between = { 1000, 60000 },
              description = "HTTP timeout in milliseconds for Akeyless API calls.",
            },
          },
          {
            ttl = typedefs.ttl {
              default = 0,
              description = "Time-to-live (seconds) for cached secrets. 0 disables rotation.",
            },
          },
          {
            neg_ttl = typedefs.ttl {
              default = 0,
              description = "Time-to-live (seconds) for caching failed secret lookups.",
            },
          },
          {
            resurrect_ttl = typedefs.ttl {
              default = 30,
              description = "Seconds to keep using expired secrets while retrying after vault errors.",
            },
          },
          {
            base64_decode = {
              type = "boolean",
              default = false,
              description = "Decode all secrets in this vault as base64.",
            },
          },
        },
      },
    },
  },
}
