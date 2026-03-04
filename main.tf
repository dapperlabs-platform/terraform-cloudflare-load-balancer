# Health monitors — one resource per entry in var.monitors
resource "cloudflare_load_balancer_monitor" "this" {
  for_each = var.monitors

  account_id  = var.account_id
  type        = each.value.type
  description = each.value.description
  interval    = each.value.interval
  timeout     = each.value.timeout
  retries     = each.value.retries
  port        = each.value.port

  # HTTP/HTTPS only
  path             = contains(["http", "https"], each.value.type) ? each.value.path : null
  expected_codes   = contains(["http", "https"], each.value.type) ? each.value.expected_codes : null
  method           = contains(["http", "https"], each.value.type) ? each.value.method : null
  follow_redirects = contains(["http", "https"], each.value.type) ? each.value.follow_redirects : null

  # HTTPS only
  allow_insecure = each.value.type == "https" ? each.value.allow_insecure : null

  dynamic "header" {
    for_each = each.value.header
    content {
      header = header.key
      values = header.value
    }
  }
}

# One pool per entry in var.pools (e.g. one per cluster region)
resource "cloudflare_load_balancer_pool" "this" {
  for_each = var.pools

  account_id      = var.account_id
  name            = each.key
  description     = each.value.description
  enabled         = each.value.enabled
  minimum_origins = each.value.minimum_origins
  monitor         = cloudflare_load_balancer_monitor.this[each.value.monitor_key].id
  latitude        = each.value.latitude
  longitude       = each.value.longitude

  dynamic "origins" {
    for_each = each.value.origins
    content {
      name    = origins.value.name
      address = origins.value.address
      weight  = origins.value.weight
      enabled = origins.value.enabled
    }
  }
}

# One load balancer per hostname — each shares the same pool configuration
resource "cloudflare_load_balancer" "this" {
  for_each = toset(var.hostnames)

  zone_id          = var.zone_id
  name             = each.value
  description      = var.description
  proxied          = var.proxied
  ttl              = var.proxied ? null : var.ttl
  steering_policy  = var.steering_policy
  session_affinity = var.session_affinity

  default_pool_ids = [for k in var.default_pool_keys : cloudflare_load_balancer_pool.this[k].id]
  fallback_pool_id = cloudflare_load_balancer_pool.this[var.fallback_pool_key].id

  dynamic "region_pools" {
    for_each = var.region_pools
    content {
      region   = region_pools.value.region
      pool_ids = [for k in region_pools.value.pool_keys : cloudflare_load_balancer_pool.this[k].id]
    }
  }

  dynamic "pop_pools" {
    for_each = var.pop_pools
    content {
      pop      = pop_pools.value.pop
      pool_ids = [for k in pop_pools.value.pool_keys : cloudflare_load_balancer_pool.this[k].id]
    }
  }

  dynamic "country_pools" {
    for_each = var.country_pools
    content {
      country  = country_pools.value.country
      pool_ids = [for k in country_pools.value.pool_keys : cloudflare_load_balancer_pool.this[k].id]
    }
  }
}
