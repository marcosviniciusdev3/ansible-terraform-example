output "webservers-dns" {
  description = "Webserver public DNS"
  value       = aws_instance.webserver[*].public_dns
}
