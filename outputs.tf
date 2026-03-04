output "load_balancer_ids" {
  description = "Map of hostname to load balancer ID"
  value = {
    for hostname, lb in cloudflare_load_balancer.this : hostname => lb.id
  }
}

output "load_balancer_hostnames" {
  description = "Map of hostname to the Cloudflare-assigned LB CNAME (if applicable)"
  value = {
    for hostname, lb in cloudflare_load_balancer.this : hostname => lb.name
  }
}

output "pool_ids" {
  description = "Map of pool key to Cloudflare pool ID"
  value = {
    for name, pool in cloudflare_load_balancer_pool.this : name => pool.id
  }
}

output "monitor_ids" {
  description = "Map of monitor key to Cloudflare monitor ID"
  value = {
    for key, monitor in cloudflare_load_balancer_monitor.this : key => monitor.id
  }
}
