output "instance_id" {
  description = "ID of the Tailscale EC2 instance"
  value       = aws_instance.tailscale.id
}

output "public_ip" {
  description = "Elastic IP address of the Tailscale instance"
  value       = aws_eip.tailscale_eip.public_ip
}

output "private_ip" {
  description = "Private IP address of the Tailscale instance"
  value       = aws_instance.tailscale.private_ip
}

output "security_group_id" {
  description = "ID of the security group attached to the Tailscale instance"
  value       = aws_security_group.tailscale_sg.id
}

output "tailscale_status" {
  description = "Instructions for checking Tailscale status"
  value = {
    ssh_command     = var.key_name != null ? "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.tailscale_eip.public_ip}" : "Use AWS Systems Manager Session Manager to connect"
    status_command  = "sudo /usr/local/bin/tailscale-status.sh"
    log_file        = "/var/log/tailscale-setup.log"
    service_status  = "sudo systemctl status tailscaled"
  }
}

output "instance_arn" {
  description = "ARN of the Tailscale EC2 instance"
  value       = aws_instance.tailscale.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the instance"
  value       = aws_iam_role.tailscale_role.arn
}