variable "name" {
  description = "Name to give to the vm."
  type        = string
}

variable "network_port" {
  description = "Network port to assign to the node. Should be of type openstack_networking_port_v2"
  type        = any
}

variable "server_group" {
  description = "Server group to assign to the node. Should be of type openstack_compute_servergroup_v2"
  type        = any
}

variable "image_source" {
  description = "Source of the vm's image"
  type = object({
    image_id = optional(string, "")
    volume_id = optional(string, "")
  })

  validation {
    condition     = var.image_source.image_id != "" || var.image_source.volume_id != ""
    error_message = "Either image_source.image_id or image_source.volume_id need to be defined."
  }
}

variable "data_volume_id" {
  description = "Id for an optional separate disk volume to attach to the vm on postgres' data path"
  type        = string
  default     = ""
}

variable "flavor_id" {
  description = "ID of the VM flavor"
  type = string
}

variable "keypair_name" {
  description = "Name of the keypair that will be used by admins to ssh to the node"
  type = string
}

variable "chrony" {
  description = "Chrony configuration for ntp. If enabled, chrony is installed and configured, else the default image ntp settings are kept"
  type        = object({
    enabled = bool,
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server
    servers = list(object({
      url = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool
    pools = list(object({
      url = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep
    makestep = object({
      threshold = number,
      limit = number
    })
  })
  default = {
    enabled = false
    servers = []
    pools = []
    makestep = {
      threshold = 0,
      limit = 0
    }
  }
}

variable "fluentbit" {
  description = "Fluent-bit configuration"
  sensitive = true
  type = object({
    enabled = bool
    patroni_tag = string
    node_exporter_tag = string
    metrics = optional(object({
      enabled = bool
      port    = number
    }), {
      enabled = false
      port = 0
    })
    forward = object({
      domain = string
      port = number
      hostname = string
      shared_key = string
      ca_cert = string
    })
  })
  default = {
    enabled = false
    patroni_tag = ""
    node_exporter_tag = ""
    metrics = {
      enabled = false
      port = 0
    }
    forward = {
      domain = ""
      port = 0
      hostname = ""
      shared_key = ""
      ca_cert = ""
    }
  }
}

variable "vault_agent" {
  type = object({
    enabled = bool
    auth_method = object({
      config = object({
        role_id   = string
        secret_id = string
      })
    })
    vault_address   = string
    vault_ca_cert   = string
  })
  default = {
    enabled = false
    auth_method = {
      config = {
        role_id   = ""
        secret_id = ""
      }
    }
    vault_address = ""
    vault_ca_cert = ""
  }
}

variable "fluentbit_dynamic_config" {
  description = "Parameters for fluent-bit dynamic config if it is enabled"
  type = object({
    enabled = bool
    source  = string
    etcd    = optional(object({
      key_prefix     = string
      endpoints      = list(string)
      ca_certificate = string
      client         = object({
        certificate = string
        key         = string
        username    = string
        password    = string
      })
      vault_agent_secret_path = optional(string, "")
    }), {
      key_prefix     = ""
      endpoints      = []
      ca_certificate = ""
      client         = {
        certificate = ""
        key         = ""
        username    = ""
        password    = ""
      }
      vault_agent_secret_path = ""
    })
    git     = optional(object({
      repo             = string
      ref              = string
      path             = string
      trusted_gpg_keys = optional(list(string), [])
      auth             = object({
        client_ssh_key         = string
        server_ssh_fingerprint = string
        client_ssh_user        = optional(string, "")
      })
    }), {
      repo             = ""
      ref              = ""
      path             = ""
      trusted_gpg_keys = []
      auth             = {
        client_ssh_key         = ""
        server_ssh_fingerprint = ""
        client_ssh_user        = ""
      }
    })
  })
  default = {
    enabled = false
    source = "etcd"
    etcd = {
      key_prefix     = ""
      endpoints      = []
      ca_certificate = ""
      client         = {
        certificate = ""
        key         = ""
        username    = ""
        password    = ""
      }
      vault_agent_secret_path = ""
    }
    git  = {
      repo             = ""
      ref              = ""
      path             = ""
      trusted_gpg_keys = []
      auth             = {
        client_ssh_key         = ""
        server_ssh_fingerprint = ""
        client_ssh_user        = ""
      }
    }
  }

  validation {
    condition     = contains(["etcd", "git"], var.fluentbit_dynamic_config.source)
    error_message = "fluentbit_dynamic_config.source must be 'etcd' or 'git'."
  }
}

variable "postgres" {
  description = "Postgres configurations"
  sensitive   = true
  type = object({
    params = optional(list(object({
      key = string,
      value = string,
    })), []),
    replicator_password = string,
    superuser_password = string,
    ca_certificate = string,
    server_certificate = string,
    server_key = string,
  })
}

variable "etcd" {
  description = "Etcd configurations"
  sensitive   = true
  type = object({
      endpoints = list(string),
      ca_cert = string,
      username = string,
      password = string,
  })
}

variable "patroni" {
  description = "Patroni configurations"
  sensitive   = true
  type = object({
    scope = string
    namespace = string
    name = string
    ttl = number
    loop_wait = number
    retry_timeout = number
    master_start_timeout = number
    master_stop_timeout = number
    watchdog_safety_margin = number
    use_pg_rewind          = bool
    is_synchronous         = bool
    synchronous_settings   = optional(object({
      strict = bool
      synchronous_node_count = number
    }), {
      strict = true
      synchronous_node_count = 1
    })
    asynchronous_settings  = optional(object({
      maximum_lag_on_failover = number
    }), {
      //1MB
      maximum_lag_on_failover = 1048576
    })
    client_certificate = string
    client_key = string
  })
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type = bool
  default = true
}