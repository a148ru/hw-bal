locals {
    ssh_key = sensitive(file("~/.ssh/id_ed25519.pub"))
}