resource "aws_instance" "client" {
  ami             = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  count           = "${var.client}"
  security_groups = ["${aws_security_group.cloudera.name}"]
  placement_group = "${aws_placement_group.cloudera.id}"
  subnet_id       = var.subnet_id

  root_block_device {
    volume_type           = "${var.volume_type}"
    volume_size           = "${var.volume_size}"
    iops                  = "${var.iops}"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.tag_name}-client"
  }

  volume_tags = {
    Name = "${var.tag_name}-client"
  }

  connection {
    host        = self.public_ip
    user        = "${lookup(var.user, var.platform)}"
    private_key = "${file("${var.key_path}")}"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/${var.platform}/base.sh",
      "${path.module}/../scripts/all/anaconda.sh",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/${var.platform}/kerberos-node.sh"
    destination = "/tmp/kerberos-node.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kerberos-node.sh",
      "/tmp/kerberos-node.sh ${aws_instance.cdh_server[0].private_ip}",
    ]
  }
}
