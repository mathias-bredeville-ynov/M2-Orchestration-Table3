vault {
  address = "https://51.161.42.245:8200"

  tls_skip_verify = true
}

auto_auth {
  method {
    type = "approle"

    config = {
      role_id_file_path   = "/vault/auth/role_id"
      secret_id_file_path = "/vault/auth/secret_id"

      remove_secret_id_file_after_reading = false
    }
  }
}

template {
  source      = "/vault/templates/db_password.ctmpl"
  destination = "/vault/secrets/db_password"
  perms       = "0444"
}

template {
  source      = "/vault/templates/db_root_password.ctmpl"
  destination = "/vault/secrets/db_root_password"
  perms       = "0444"
}

template {
  source      = "/vault/templates/nextcloud_admin_password.ctmpl"
  destination = "/vault/secrets/nextcloud_admin_password"
  perms       = "0444"
}
