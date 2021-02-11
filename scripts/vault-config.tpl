#!/bin/bash

# sleep for net configs to take effect
sleep 90s
# restart network services in case nat wasn't fully there
#sudo systemctl status NetworkManager.service
touch /tmp/log.txt
echo "about to do apt-get install software" >> /tmp/log.txt
# Need this to do apt-add-repository
sudo apt-get install software-properties-common -y

#add hashi repo
sudo curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update -y && sudo apt-get install vault -y

# Install some software
sudo apt-get update -y
sudo apt-get install wget -y


# Create some files to hold some info for us
touch /tmp/consul-version
touch /tmp/my-ip

sudo cat << EOF >> /tmp/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF
sudo mv /tmp/vault.service /etc/systemd/system/

# set up vault.hcl

sudo cat << EOF >> /tmp/vault.hcl
ui = true

storage "file"{
  path = "/opt/vault/data"

}

listner "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file  = "/opt/vault/tls/tls.key"
}

# listener "tcp" {
#   address     = "127.0.0.1:8200"
#   tls_disable = 1
# }

# telemetry {
#   statsite_address = "127.0.0.1:8125"
#   disable_hostname = true
# }

EOF

sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
sudo mv /tmp/vault.hcl /etc/vault.d
sudo chown --recursive vault:vault /etc/vault.d
sudo chmod 640 /etc/vault.d/vault.hcl
sudo systemctl enable vault
#sudo systemctl start vault

# get IP
export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo $IP_INTERNAL >> /tmp/my-ip





echo "Finished script" >> /tmp/vault-status
