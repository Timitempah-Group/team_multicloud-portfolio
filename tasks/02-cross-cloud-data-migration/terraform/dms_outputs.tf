output "dms_replication_instance_public_ip" {
  value = aws_dms_replication_instance.main.replication_instance_public_ips[0]
}

output "dms_replication_task_arn" {
  value = aws_dms_replication_task.main.replication_task_arn
}
