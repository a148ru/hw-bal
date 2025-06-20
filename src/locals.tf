locals {
  ssh_key = sensitive(file("~/.ssh/id_ed25519.pub"))
  key_name    = "bucket-key" # Имя ключа KMS.
  key_desc    = "Ключ для шифрования бакетов"
}
