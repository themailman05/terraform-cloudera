resource "aws_instance" "cdh_server" {
  ami             = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  count           = "${var.cdh_server}"
  security_groups = ["${aws_security_group.cloudera.id}"]
  placement_group = "${aws_placement_group.cloudera.id}"
  subnet_id       = var.private_subnet_block[0].id

  root_block_device {
    volume_type           = "${var.volume_type}"
    volume_size           = "${var.volume_size}"
    iops                  = "${var.iops}"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.tag_name}-cdh-server"
  }

  volume_tags = {
    Name = "${var.tag_name}-cdh-server"
  }

  connection {
    host        = self.public_ip
    user        = "${lookup(var.user, var.platform)}"
    private_key = "${file("${var.key_path}")}"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/${var.platform}/base.sh",
      "${path.module}/../scripts/${var.platform}/cloudera-repo.sh",
      "${path.module}/../scripts/${var.platform}/java.sh",
    ]

    # Livy has to be executed as a post-install step
    # "${path.module}/../scripts/${var.platform}/livy.sh",
  }

  provisioner "remote-exec" {
    script = "${path.module}/../scripts/${var.platform}/cdh-server.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/${var.platform}/cdh-agent.sh"
    destination = "/tmp/cdh-agent.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/cdh-agent.sh",
      "/tmp/cdh-agent.sh ${aws_instance.cdh_server[0].private_ip}",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/${var.platform}/kerberos-server.sh"
    destination = "/tmp/kerberos-server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kerberos-server.sh",
      "/tmp/kerberos-server.sh ${aws_instance.cdh_server[0].private_ip}",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/${var.platform}/csd-spark2.sh",
      "${path.module}/../scripts/${var.platform}/csd-dsw.sh",
      "${path.module}/../scripts/${var.platform}/restart-cloudera-manager.sh",
    ]
  }
}

resource "aws_instance" "cdh_node" {
  ami             = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  count           = "${var.cdh_nodes}"
  security_groups = ["${aws_security_group.cloudera.id}"]
  placement_group = "${aws_placement_group.cloudera.id}"
  subnet_id       = var.public_subnet_block[count.index].id

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size}"
    iops        = "${var.iops}"
  }

  tags = {
    Name = "${var.tag_name}-cdh-node-${count.index}"
  }

  volume_tags = {
    Name = "${var.tag_name}-cdh-node-${count.index}"
  }

  connection {
    host        = self.public_ip
    user        = "${lookup(var.user, var.platform)}"
    private_key = "${file("${var.key_path}")}"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/${var.platform}/base.sh",
      "${path.module}/../scripts/${var.platform}/cloudera-repo.sh",
      "${path.module}/../scripts/${var.platform}/java.sh",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/${var.platform}/cdh-agent.sh"
    destination = "/tmp/cdh-agent.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/cdh-agent.sh",
      "/tmp/cdh-agent.sh ${aws_instance.cdh_server[0].private_ip}",
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
