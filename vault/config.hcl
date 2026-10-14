storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true   # acceptable : Vault n'est joignable que depuis la VM elle-même
}

api_addr      = "http://127.0.0.1:8200"
disable_mlock = true
ui            = true