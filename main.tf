terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.115.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = "cloud-nimbus-734"
  folder_id                = "b1g7v1n2hqf8kv68hn19"
  zone                     = "ru-central1-a"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

#Создание подсети в yandex-cloud
resource "yandex_vpc_subnet" "my_subnet" {
  name           = "final-subnet-v2"
  zone           = "ru-central1-a"
  network_id     = "enpo88653hqglubaalv2"
  v4_cidr_blocks = ["10.0.4.0/24"]
}

#Создание VM, пользователя, передача ключа
resource "yandex_compute_instance" "vm" {
  name = "final-vm"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.my_subnet.id
    nat       = true
  }

  metadata = {
    user-data = <<EOF
  #cloud-config
  users:
    - name: devops
      groups: sudo
      shell: /bin/bash
      sudo: ['ALL=(ALL) NOPASSWD:ALL']
      ssh-authorized-keys:
        - ${file("~/.ssh/id_ed25519.pub")}
  EOF
  }
}

#Вывод ip vm в терминал послн создания
output "vm_ip" {
  value = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}
