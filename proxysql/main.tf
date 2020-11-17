locals {
  consul_datacenter = "dc1"
  consul_address = "localhost:8500"
}

provider "consul" {
  address    = local.consul_address
  datacenter = local.consul_datacenter
}

data "template_file" "proxysql_cnfg" {
  template = file("proxysql_cnfg.sql")
}

resource "consul_keys" "proxysql_configuration" {
  datacenter = local.consul_datacenter

  key {
    path   = "proxysql/config/config.sql"
    delete = true

    value = data.template_file.proxysql_cnfg.rendered
  }
}
