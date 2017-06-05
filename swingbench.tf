
resource "opc_compute_instance" "swingBench_instance_1" {
  name       = "swingBench_instance_1"
  label      = "swingbench using terraform"
  shape      = "oc3"
  image_list = "/Compute-${var.domain}/${var.user}/Ubuntu.16.04-LTS.amd64.20170330"
  ssh_keys   = ["${opc_compute_ssh_key.swingBenchKey.name}"]

 /* storage {
    index  = 1
    volume = "${opc_compute_storage_volume.terraform_bootable_storage.name}"
  } */
}

resource "opc_compute_ssh_key" "swingBenchKey" {
  name    = "swingBenchKey"
  key     = "${file(var.ssh_publicKey_file)}"
  enabled = true
}

resource "opc_compute_ip_reservation" "reserve_ip_swingBench" {
  parent_pool = "/oracle/public/ippool"
  permanent   = true
  tags        = []
}

resource "opc_compute_ip_association" "instance_accociateIP_swingbench" {
  vcable      = "${opc_compute_instance.swingBench_instance_1.vcable}"
  parent_pool = "ipreservation:${opc_compute_ip_reservation.reserve_ip_swingBench.name}"
}


#security stuff below

resource "opc_compute_sec_rule" "SSH_ACCESS_swingbench" {
  name             = "SSH_ACCESS_swingbench"
  source_list      = "seciplist:${opc_compute_security_ip_list.public_internet_swingBench.name}"
  destination_list = "seclist:${opc_compute_security_list.SSH_ALLOW_swingBench.name}"
  action           = "permit"
  application      = "${opc_compute_security_application.ssh_port_swingBench.name}"
}

resource "opc_compute_security_application" "ssh_port_swingBench" {
  name     = "ssh_port_swingBench"
  protocol = "tcp"
  dport    = "22"
}

resource "opc_compute_security_association" "associate_SSH_swingBench" {
  name    = "associate_SSH_swingBench"
  vcable  = "${opc_compute_instance.swingBench_instance_1.vcable}"
  seclist = "${opc_compute_security_list.SSH_ALLOW_swingBench.name}"
}

resource "opc_compute_security_ip_list" "public_internet_swingBench" {
  name       = "public_internet_swingBench"
  ip_entries = ["0.0.0.0/0"]
}

resource "opc_compute_security_list" "SSH_ALLOW_swingBench" {
  name                 = "SSH_ALLOW_swingBench"
  policy               = "deny"      # is it permit?
  outbound_cidr_policy = "permit"
}
