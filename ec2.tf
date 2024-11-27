resource "aws_key_pair" "key" {
  key_name   = "my-ec2-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDDQDN5mGTMc8/Oj4L78c8OE9kPkB69Wcg4zEsmr6j5 matheus"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "my_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  subnet_id                   = aws_subnet.subnet_ec2_public_az_a.id
  associate_public_ip_address = true
  user_data_replace_on_change = true
  user_data                   = <<EOF
#!/bin/bash
exec > /var/log/user_data.log 2>&1
echo "Atualizando pacotes..."

sudo apt update -y
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
echo "Instalando Docker..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Iniciando e habilitando o serviço Docker..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Adicionando o usuário 'ubuntu' ao grupo 'docker'..."
sudo usermod -aG docker ubuntu
newgrp docker

echo "Finalizando script."
EOF

  tags = {
    IAC = "True"
  }
}

# Create Virtual Private Cloud
resource "aws_vpc" "vpc_ec2" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    IAC = "True"
  }
}

# Create subnet
resource "aws_subnet" "subnet_ec2_public_az_a" {
  vpc_id                  = aws_vpc.vpc_ec2.id
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    IAC = "True"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "igw_ec2" {
  vpc_id = aws_vpc.vpc_ec2.id # Definindo a vpc que terá acesso a internet

  tags = {
    IAC = "True"
  }
}

resource "aws_route_table" "rtb_ec2" {
  vpc_id = aws_vpc.vpc_ec2.id

  route {
    cidr_block = "0.0.0.0/0" # Significa que qualquer IP local ou qualquer pessoa na internet pode acessar
    # qualquer ipv4 pode acessar por conta do /0, se fosse ipv6 seria ::/0

    gateway_id = aws_internet_gateway.igw_ec2.id
  }

  tags = {
    IAC = "True"
  }
}

# Linkando a subnet e a tabela de roteamento 
resource "aws_route_table_association" "rta_ec2" {
  subnet_id      = aws_subnet.subnet_ec2_public_az_a.id
  route_table_id = aws_route_table.rtb_ec2.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_${terraform.workspace}"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc_ec2.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    IAC = "True"
  }
}

output "ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
}

