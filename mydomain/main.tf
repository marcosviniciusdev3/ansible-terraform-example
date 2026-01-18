data "aws_ami" "debian12" {
  most_recent = true

  owners = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
}

# Keys

resource "tls_private_key" "key" {
  algorithm = "ED25519"
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_openssh
  filename        = "${var.private_key_path}/webserver.key"
  file_permission = "0400"
}

resource "local_file" "public_key" {
  content         = tls_private_key.key.public_key_openssh
  filename        = "${var.private_key_path}/webserver.pub"
  file_permission = "0400"
}

resource "aws_key_pair" "admin_key" {
  key_name   = "webserver-key"
  public_key = tls_private_key.key.public_key_openssh
}

# Servers

data "cloudinit_config" "webserver-config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = file("${path.module}/scripts/cloud-init.yml")
  }
}

resource "aws_instance" "webserver" {
  count                       = 1
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.debian12.id
  security_groups             = [aws_security_group.allow_http.id, aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.admin_key.key_name
  subnet_id                   = aws_subnet.public_net.id
  user_data                   = data.cloudinit_config.webserver-config.rendered

  tags = {
    Name = "server-${count.index}"
  }

  lifecycle {
    create_before_destroy = false
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "admin"
    private_key = file(local_file.private_key.filename)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"SSH is ready!\""
    ]
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/webserver.tftpl", {
    webservers = [
      for i, inst in aws_instance.webserver :
      {
        hostname = "webserver-${i}.webservers.local"
        ip       = inst.public_ip
        env      = var.environment
      }
    ],
  })
  filename = "ansible/playbooks/inventory.ini"
}

resource "null_resource" "ansible_provisioner" {
  triggers = {
    # Re-run if any instance IP changes
    instance_ips = join(",", aws_instance.webserver.*.public_ip)
  }

  provisioner "local-exec" {
    on_failure = continue
    when       = create
    command    = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
      --key-file ${local_file.private_key.filename} \
      -i ansible/playbooks/inventory.ini \
      -u admin \
      ansible/playbooks/web-notls.yml 
    EOT
  }

  depends_on = [local_file.ansible_inventory, aws_instance.webserver]
}
