#!/bin/bash

# sleep for net configs to take effect
sleep 90s
# restart network services in case nat wasn't fully there
#sudo systemctl status NetworkManager.service

# get IP
export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo $IP_INTERNAL >> /tmp/my-ip

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
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
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
disable_mlock = true
ui = true

storage "raft"{
  path = "/opt/vault/data"
  node_id = "$HOSTNAME"
  retry_join {
    auto_join = "provider=gce project_name=${project_name} tag_value=${vault_join_tag}"
  }

}

listner "tcp" {
  address         = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable = 1
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file  = "/opt/vault/tls/tls.key"
}

telemetry {
  statsite_address = "127.0.0.1:8125"
  disable_hostname = true
}

cluster_addr = "https://IP_INTERNAL:8201"
api_addr = "https://127.0.0.1:8200"

EOF
sed -i 's/IP_INTERNAL/$IP_INTERNAL/g' /tmp/vault.hcl
sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
sudo mv /tmp/vault.hcl /etc/vault.d
sudo chown --recursive vault:vault /etc/vault.d
sudo chmod 640 /etc/vault.d/vault.hcl
sudo systemctl enable vault
sudo systemctl start vault







echo "Finished script" >> /tmp/vault-status
