output "ecs_cluster_name" {
  value = aws_ecs_cluster.webapp_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.webapp_service.name
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  value = aws_elasticache_cluster.redis.port
}

output "load_balancer_dns" {
  value = aws_lb.webapp_lb.dns_name
}

output "redis_url" {
  value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
}
