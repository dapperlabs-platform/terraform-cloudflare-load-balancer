variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID for the load balancer hostnames"
  type        = string
}

variable "zone_domain" {
  description = "Cloudflare zone domain (e.g. example.com)"
  type        = string
}

variable "hostnames" {
  description = "List of fully-qualified hostnames to create load balancers and edge certificates for (e.g. [\"app.staging.example.com\", \"api.staging.example.com\"])"
  type        = list(string)
}

variable "pools" {
  description = "Map of pool name to pool configuration. Typically one pool per origin region/cluster."
  type = map(object({
    origins = list(object({
      name    = string
      address = string
      weight  = optional(number, 1)
      enabled = optional(bool, true)
    }))
    description     = optional(string, "")
    enabled         = optional(bool, true)
    minimum_origins = optional(number, 1)
    monitor_key     = optional(string, "default")
    # Geo coordinates used for proximity steering
    latitude  = optional(number, null)
    longitude = optional(number, null)
  }))
}

variable "monitors" {
  description = "Map of named health monitor configurations. Each pool references one by key via monitor_key."
  type = map(object({
    type             = optional(string, "https")
    path             = optional(string, "/healthz")
    expected_codes   = optional(string, "2xx")
    interval         = optional(number, 60)
    timeout          = optional(number, 5)
    retries          = optional(number, 2)
    method           = optional(string, "GET")
    description      = optional(string, "")
    allow_insecure   = optional(bool, false)
    follow_redirects = optional(bool, false)
    port             = optional(number, null)
    header           = optional(map(list(string)), {})
  }))
  default = {
    default = {}
  }
}

variable "default_pool_keys" {
  description = "Ordered list of pool keys to use as the default (first = highest priority)"
  type        = list(string)
}

variable "fallback_pool_key" {
  description = "Pool key to use as the final fallback when all pools are unhealthy"
  type        = string
}

variable "steering_policy" {
  description = "Load balancing steering policy. One of: off, geo, dynamic_latency, random, proximity, least_connections"
  type        = string
  default     = "geo"
  validation {
    condition     = contains(["off", "geo", "dynamic_latency", "random", "proximity", "least_connections"], var.steering_policy)
    error_message = "steering_policy must be one of: off, geo, dynamic_latency, random, proximity, least_connections"
  }
}

variable "region_pools" {
  description = "Map Cloudflare region codes to ordered pool keys for geo steering (e.g. WNAM, ENAM, WEU)"
  type = list(object({
    region    = string
    pool_keys = list(string)
  }))
  default = []
}

variable "pop_pools" {
  description = "Map Cloudflare PoP IATA codes to ordered pool keys (e.g. LAX, JFK)"
  type = list(object({
    pop       = string
    pool_keys = list(string)
  }))
  default = []
}

variable "country_pools" {
  description = "Map ISO 3166-1 alpha-2 country codes to ordered pool keys (e.g. US, CA, GB)"
  type = list(object({
    country   = string
    pool_keys = list(string)
  }))
  default = []
}

variable "proxied" {
  description = "Whether the load balancer DNS record should be Cloudflare-proxied"
  type        = bool
  default     = true
}

variable "ttl" {
  description = "DNS TTL for the load balancer record. Only applies when proxied = false."
  type        = number
  default     = null
}

variable "session_affinity" {
  description = "Session affinity type: none, cookie, ip_cookie, header"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "cookie", "ip_cookie", "header"], var.session_affinity)
    error_message = "session_affinity must be one of: none, cookie, ip_cookie, header"
  }
}

variable "description" {
  description = "Description for the load balancer resources"
  type        = string
  default     = ""
}
