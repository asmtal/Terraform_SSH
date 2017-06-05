provider "opc" {
  user            = "${var.user}"
  password        = "${var.password}"
  identity_domain = "${var.domain}"
  endpoint        = "${var.endpoint}"
}

resource "opc_compute_instance" "terraform_instance" {
  name       = "terraform_instance"
  label      = "this is my first compute instance wusing terraform"
  shape      = "oc3"
  image_list = "/Compute-a430291/ZABUSEINI@forsythe.com/Ubuntu.16.04-LTS.amd64.20170330"
  ssh_keys   = ["${opc_compute_ssh_key.terraformKey.name}"]

  storage {
    index  = 1
    volume = "${opc_compute_storage_volume.terraform_bootable_storage.name}"
  }
}

resource "opc_compute_ssh_key" "terraformKey" {
  name    = "terraformKey"
  key     = "${file(var.ssh_publicKey_file)}"
  enabled = true
}

resource "opc_compute_ip_reservation" "reserve_ip" {
  parent_pool = "/oracle/public/ippool"
  permanent   = true
  tags        = []
}

resource "opc_compute_ip_association" "instance_accociateIP" {
  vcable      = "${opc_compute_instance.terraform_instance.vcable}"
  parent_pool = "ipreservation:${opc_compute_ip_reservation.reserve_ip.name}"
}

/*
resource "opc_compute_storage_volume" "storage_space" {
  name        = "terraform_storage_space"
  description = "creates a storage volume to attache separtly"
  size        = 10
}
*/

resource "opc_compute_storage_volume" "terraform_bootable_storage" {
  name        = "terraform_bootable_storage"
  description = "persistent bootable storage that is attached to this instance"
  size        = 10
}

#security stuff below

resource "opc_compute_sec_rule" "SSH_ACCESS" {
  name             = "SSH_ACCESS"
  source_list      = "seciplist:${opc_compute_security_ip_list.public_internet.name}"
  destination_list = "seclist:${opc_compute_security_list.SSH_ALLOW.name}"
  action           = "permit"
  application      = "${opc_compute_security_application.ssh_port.name}"
}

resource "opc_compute_security_application" "ssh_port" {
  name     = "ssh_port"
  protocol = "tcp"
  dport    = "22"
}

resource "opc_compute_security_association" "associate_SSH" {
  name    = "associate_SSH"
  vcable  = "${opc_compute_instance.terraform_instance.vcable}"
  seclist = "${opc_compute_security_list.SSH_ALLOW.name}"
}

resource "opc_compute_security_ip_list" "public_internet" {
  name       = "public_internet"
  ip_entries = ["0.0.0.0/0"]
}

resource "opc_compute_security_list" "SSH_ALLOW" {
  name                 = "SSH_ALLOW"
  policy               = "deny"      # is it permit?
  outbound_cidr_policy = "permit"
}
