package = "kong-vault-akeyless"
version = "0.1.0-1"
supported_platforms = { "linux", "macosx" }

source = {
  url = "git+https://github.com/akeyless-community/kong-akeyless-integration.git",
  tag = "v0.1.0",
}

description = {
  summary = "Akeyless vault backend for Kong Gateway Secrets Management",
  detailed = [[
    Kong Gateway vault strategy that resolves {vault://...} references against
    the Akeyless REST API. Intended for Kong Gateway Enterprise deployments.
  ]],
  homepage = "https://github.com/akeyless-community/kong-akeyless-integration",
  license = "Apache-2.0",
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.vaults.akeyless"] = "vault-strategy/kong/vaults/akeyless/init.lua",
    ["kong.vaults.akeyless.schema"] = "vault-strategy/kong/vaults/akeyless/schema.lua",
  },
}
