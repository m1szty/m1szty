#!/bin/bash

#Скрипт должен быть запущен с правами root
#1) Скачать необходимые пакеты
#2) Добавить открытый ключ в файл authorized_keys.
#3) Завести тачку в домен.
#3.1) Проверить доступность dc
#3.2) Завести в домен
#4) Зашить ключ разблокировки LUKS в tpm
#5) Установить агент ДБ, Растдеск и Cisco Secure Client


#Переменные
export AGENT_SERVER_HOSTS="https://10.111.102.73:4444" 
export SOFTWARE_CENTER_HOSTS="https://10.111.102.73:9400"
CRYPTED_PART=$(awk '/crypto_LUKS/ {print}' lsblk | cut -d " " -f1)
read -p "Учетка оператора: " WADMIN


  if [ "$(id -u)" != 0 ]; then 
    echo "ERROR"
    exit
  fi

apt update
apt install -y sssd-ad sssd-tools realmd adcli clevis clevis-tpm2 clevis-luks clevis-initramfs initramfs-tools tss2
apt install openssh-server -y 
systemctl enable --now ssh
  
  if id innohead; then 
    mkdir -m 700 /home/innohead/.ssh &&  sh -c 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCujmZ9X6wpm8Qx//aDaSvOMRgMj/ERlrqVMwSrDAHyZnTOHVzUcpBQ4ij4Xh6hL4NqajZjv8Bsnnn5goiqV3QOK8m/jUz3ORu+6msDKTnAfZ+xh9ZGR1VQEFO64QPktN10wiysEtcIjlchnWzdn0Tes3SyGcmxfNaPRceBdu5ky8994PosEklK1lnOo6MhFcpAqg0b0OeAPXH37xUEz3Nph+8Xs4oNWmHrl2uWv2OEzm+odUkCAynccS2Hu/ac29Qc3FPQUY+DPQnpM9DctIWdf7WM7M/ArDFPREfoYUDy2OkwSFnTqccsGWUNIti0iYY1UikTTw6tvMIeAHEeXWp8H0AnrkNOQfEFF3MhcEXP2NYZo2X1kf2xF+LHLS5N4O72r1lxnu8feQ+0PisP4zt8NPAzmrdqjbfuYGYA0xi9cTXgZeCtONoIhERPtdvI/rJO9nKR+6QGbse5S81axrujWaZ8rTpQQSv6MQHZ8Oo7OhU020BB0VrxwMLdrH2aiPkGTlW6D8FFjY9ZSDbP7ud0tdtCiI62sAj9ZgzcgbnsHa8mueoVE79Y4Q0hStFnNcRDd3Xq3KcYrvi2iVKbqtpZ2lwkOVRMvnNn3J5BQeNBw/qkRietpylO9my8/3p1pYGeA8ZcG+mDz0FRVH/i8/hQVTVBlz7jFHmNpghdRiZggw==" > /home/innohead/.ssh/authorized_keys'
    chown -R innohead:innohead /home/innohead/.ssh/ && chmod 600 /home/innohead/.ssh/authorized_keys; 
  else 
    useradd -m -s /bin/bash innohead && mkdir -m 700 /home/innohead/.ssh && 
    sh -c 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCujmZ9X6wpm8Qx//aDaSvOMRgMj/ERlrqVMwSrDAHyZnTOHVzUcpBQ4ij4Xh6hL4NqajZjv8Bsnnn5goiqV3QOK8m/jUz3ORu+6msDKTnAfZ+xh9ZGR1VQEFO64QPktN10wiysEtcIjlchnWzdn0Tes3SyGcmxfNaPRceBdu5ky8994PosEklK1lnOo6MhFcpAqg0b0OeAPXH37xUEz3Nph+8Xs4oNWmHrl2uWv2OEzm+odUkCAynccS2Hu/ac29Qc3FPQUY+DPQnpM9DctIWdf7WM7M/ArDFPREfoYUDy2OkwSFnTqccsGWUNIti0iYY1UikTTw6tvMIeAHEeXWp8H0AnrkNOQfEFF3MhcEXP2NYZo2X1kf2xF+LHLS5N4O72r1lxnu8feQ+0PisP4zt8NPAzmrdqjbfuYGYA0xi9cTXgZeCtONoIhERPtdvI/rJO9nKR+6QGbse5S81axrujWaZ8rTpQQSv6MQHZ8Oo7OhU020BB0VrxwMLdrH2aiPkGTlW6D8FFjY9ZSDbP7ud0tdtCiI62sAj9ZgzcgbnsHa8mueoVE79Y4Q0hStFnNcRDd3Xq3KcYrvi2iVKbqtpZ2lwkOVRMvnNn3J5BQeNBw/qkRietpylO9my8/3p1pYGeA8ZcG+mDz0FRVH/i8/hQVTVBlz7jFHmNpghdRiZggw==" > /home/innohead/.ssh/authorized_keys' && \
    sh -c 'echo "innohead ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-innohead' && 
    chown -R innohead:innohead /home/innohead/.ssh/ && chmod 600 /home/innohead/.ssh/authorized_keys; 
  fi

realm join dc1.office.innoseti.ru -U "${WADMIN}" --computer-ou="OU=OFFICE_COMPS_UBUNTU"
pam-auth-update --enable mkhomedir
clevis luks bind -d /dev/"${CRYPTED_PART}" tpm2 '{"pcr_bank":"sha256"}'
update-initramfs -u -k all

#Установка дефолтной оболочки
sudo grep -q '^DefaultSession=' /etc/gdm3/custom.conf && 
sudo sed -i 's|^DefaultSession=.*|DefaultSession=gnome-xorg.desktop|' /etc/gdm3/custom.conf || 
sudo sed -i '/^\[daemon\]/a DefaultSession=gnome-xorg.desktop' /etc/gdm3/custom.conftzubov@office.innoseti.ru@L098



#Агент ИБ
apt install lsb-release; apt install ./linux-agent-4.7.0.118.ubuntu22.04.deb


#sudo usermod -aG sudo username@office.innoseti.ru # Это можно сделать руками.
#Извлечение серта и ключа из pfx
#read -p "login:" LOGIN
#read -p "pfx pass:" pass
#mkdir -p .cisco/certificates/client/private
#openssl pkcs12 -in $LOGIN.pfx -clcerts -nokeys -out $LOGIN.pem -passin pass:$pass
#openssl pkcs12 -in $LOGIN.pfx -nocerts -nodes  -out $LOGIN.key -passin pass:$pass
#mv $LOGIN.key .cisco/certificates/client/private
#mv $LOGIN.pem .cisco/certificates/client





