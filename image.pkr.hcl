variable "region" {
  type    = string
  default = "us-east-2"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "alpine" {
  ami_name              = "aabor@alpine-arm64"
  instance_type         = "t4g.small"
  region                = var.region
  force_deregister      = true
  force_delete_snapshot = true
  ssh_username          = "alpine"
  source_ami_filter {
    filters = {
      # aws ec2 describe-images --image-ids ami-02b972ad7d6bdaf13
      name                = "alpine-3.18.2-aarch64-uefi-cloudinit-r0"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      state               = "available"
    }
    most_recent = true
    owners      = ["538276064493"]
  }
  tags = {
    OS_Version    = "Alpine arm64"
    Release       = "3.18.2"
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Extra         = "{{ .SourceAMITags.TagName }}"
    Timestamp     = local.timestamp
  }
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 1
    volume_type           = "gp3"
    delete_on_termination = true
  }
  #   ami_block_device_mappings {
  #   device_name  = "/dev/sdb1"
  #   virtual_name = "ephemeral0"
  # }
  # ami_block_device_mappings {
  #   device_name  = "/dev/sdc2"
  #   virtual_name = "ephemeral1"
  # }
}
# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.alpine"]

  provisioner "file" {
    source      = "./keys/id_rsa.pub"
    destination = "/tmp/id_rsa.pub"
  }
  provisioner "file" {
    source      = "./keys/aws.pub"
    destination = "/tmp/"
  }
  provisioner "file" {
    source = "./squid.conf"
    destination = "/tmp/"
  }
  provisioner "file" {
    source = "../../.squid/.htpasswd"
    destination = "/tmp/"
  }
  provisioner "shell" {
    script = "./setup-auto.sh"
  }
}
