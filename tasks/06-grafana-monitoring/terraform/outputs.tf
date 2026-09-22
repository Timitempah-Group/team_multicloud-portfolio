output "grafana_workspace_id" {
  value = aws_grafana_workspace.main.id
}

output "grafana_workspace_url" {
  value = aws_grafana_workspace.main.endpoint
}
