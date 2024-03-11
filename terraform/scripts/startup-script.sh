#!/bin/bash
# Copyright (C) SchedMD LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

SLURM_DIR=/slurm
FLAGFILE=$SLURM_DIR/slurm_configured_do_not_remove
SCRIPTS_DIR=$SLURM_DIR/scripts

METADATA_SERVER="metadata.google.internal"
URL="http://$METADATA_SERVER/computeMetadata/v1"
HEADER="Metadata-Flavor:Google"
CURL="curl -sS --fail --header $HEADER"

function fetch_scripts {
	# fetch project metadata
	if ! CLUSTER=$($CURL $URL/instance/attributes/slurm_cluster_name); then
		echo cluster name not found in instance metadata, quitting
		return 1
	fi
	if ! META_DEVEL=$($CURL $URL/project/attributes/$CLUSTER-slurm-devel); then
        echo $CLUSTER-slurm-devel not found in project metadata, skipping script update
		return
	fi
	echo devel data found in project metadata, looking to update scripts
	if STARTUP_SCRIPT=$(jq -re '."startup-script"' <<< "$META_DEVEL"); then
		echo updating startup.sh from project metadata
		printf '%s' "$STARTUP_SCRIPT" > $STARTUP_SCRIPT_FILE
	else
		echo startup-script not found in project metadata, skipping update
	fi
	if SETUP_SCRIPT=$(jq -re '."setup-script"' <<< "$META_DEVEL"); then
		echo updating setup.py from project metadata
		printf '%s' "$SETUP_SCRIPT" > $SETUP_SCRIPT_FILE
	else
		echo setup-script not found in project metadata, skipping update
	fi
	if UTIL_SCRIPT=$(jq -re '."util-script"' <<< "$META_DEVEL"); then
		echo updating util.py from project metadata
		printf '%s' "$UTIL_SCRIPT" > $UTIL_SCRIPT_FILE
	else
		echo util-script not found in project metadata, skipping update
	fi
	if RESUME_SCRIPT=$(jq -re '."slurm-resume"' <<< "$META_DEVEL"); then
		echo updating resume.py from project metadata
		printf '%s' "$RESUME_SCRIPT" > $RESUME_SCRIPT_FILE
	else
		echo slurm-resume not found in project metadata, skipping update
	fi
	if SUSPEND_SCRIPT=$(jq -re '."slurm-suspend"' <<< "$META_DEVEL"); then
		echo updating suspend.py from project metadata
		printf '%s' "$SUSPEND_SCRIPT" > $SUSPEND_SCRIPT_FILE
	else
		echo slurm-suspend not found in project metadata, skipping update
	fi
	if SLURMSYNC_SCRIPT=$(jq -re '."slurmsync"' <<< "$META_DEVEL"); then
		echo updating slurmsync.py from project metadata
		printf '%s' "$SLURMSYNC_SCRIPT" > $SLURMSYNC_SCRIPT_FILE
	else
		echo slurmsync not found in project metadata, skipping update
	fi
	if SLURMEVENTD_SCRIPT=$(jq -re '."slurmeventd"' <<< "$META_DEVEL"); then
		echo "updating slurmeventd.py from project metadata"
		printf '%s' "$SLURMEVENTD_SCRIPT" > $SLURMEVENTD_SCRIPT_FILE
	else
		echo "slurmeventd not found in project metadata, skipping update"
	fi
}

PING_METADATA="ping -q -w1 -c1 $METADATA_SERVER"
echo $PING_METADATA
for i in $(seq 10); do
    [ $i -gt 1 ] && sleep 5;
    $PING_METADATA > /dev/null && s=0 && break || s=$?;
    echo failed to contact metadata server, will retry
done
if [ $s -ne 0 ]; then
    echo Unable to contact metadata server, aborting
    wall -n '*** Slurm setup failed in the startup script! see `journalctl -u google-startup-scripts` ***'
    exit 1
else
    echo Successfully contacted metadata server
fi

GOOGLE_DNS=8.8.8.8
PING_GOOGLE="ping -q -w1 -c1 $GOOGLE_DNS"
echo $PING_GOOGLE
for i in $(seq 5); do
    [ $i -gt 1 ] && sleep 2;
    $PING_GOOGLE > /dev/null && s=0 && break || s=$?;
    echo failed to ping Google DNS, will retry
done
if [ $s -ne 0 ]; then
    echo No internet access detected
else
    echo Internet access detected
fi

mkdir -p $SCRIPTS_DIR

STARTUP_SCRIPT_FILE=$SCRIPTS_DIR/startup.sh
SETUP_SCRIPT_FILE=$SCRIPTS_DIR/setup.py
UTIL_SCRIPT_FILE=$SCRIPTS_DIR/util.py
RESUME_SCRIPT_FILE=$SCRIPTS_DIR/resume.py
SUSPEND_SCRIPT_FILE=$SCRIPTS_DIR/suspend.py
SLURMSYNC_SCRIPT_FILE=$SCRIPTS_DIR/slurmsync.py
SLURMEVENTD_SCRIPT_FILE=$SCRIPTS_DIR/slurmeventd.py
fetch_scripts

if [ -f $FLAGFILE ]; then
	echo "Slurm was previously configured, quitting"
	exit 0
fi
touch $FLAGFILE

echo "running python cluster setup script"
chmod +x $SETUP_SCRIPT_FILE
python3 $SCRIPTS_DIR/util.py
exec $SETUP_SCRIPT_FILE

# Install grafana
apt-get install -y apt-transport-https software-properties-common wget
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list
# Updates the list of available packages
apt-get update -y
# Installs the latest OSS release:
apt-get install -y grafana

## To do 

# if GRAFANA_ALLOWED_DOMAINS=$($CURL $URL/instance/attributes/grafana_allowed_domains); then
#     echo  Allowed domains ${GRAFANA_ALLOWED_DOMAINS} found for grafana. Configuring workspace login.
#     GRAFANA_HOSTED_DOMAIN=$($CURL $URL/instance/attributes/grafana_hosted_domain)

#     # Append to grafana.ini to allow sign-in via Google Workspace accounts
#     cat <<EOT >> /etc/grafana.ini
# [auth.google]
# enabled = true
# allow_sign_up = true
# auto_login = false
# client_id = ${CLIENT_ID}
# client_secret = ${CLIENT_SECRET}
# scopes = openid email profile
# auth_url = https://accounts.google.com/o/oauth2/v2/auth
# token_url = https://oauth2.googleapis.com/token
# api_url = https://openidconnect.googleapis.com/v1/userinfo
# allowed_domains = ${GRAFANA_ALLOWED_DOMAINS}
# hosted_domain = ${GRAFANA_HOSTED_DOMAIN}
# use_pkce = true
# EOT
# fi

# If IAP is used 
# cat <<EOT >> /etc/grafana.ini
# [auth.jwt]
# enabled = true
# header_name = "X-Goog-Iap-Jwt-Assertion"
# username_claim = "email"
# email_claim = "email"
# jwk_set_url = "https://www.gstatic.com/iap/verify/public_key-jwk"
# expect_claims = '{"iss": "https://cloud.google.com/iap"}'
# auto_sign_up = true
# EOT

# - Add dashboard that pre-defines the dashboards
#   > Get slurm-dashboard.json
#   > Copy to /etc/grafana/provisioning/dashboards/slurm-dashboard.json
#
# - Add .yml that pre-defines the datasets (including the Cloud Logs Explorer filtered log metrics)
cat > /etc/grafana/provisioning/datasources/datasources.yaml << EOT
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://localhost:9090
    isDefault: true
EOT
chown root:grafana /etc/grafana/provisioning/datasources/datasources.yaml

# Install prometheus
groupadd --system prometheus
useradd \
    --system \
    --no-create-home \
    --shell /bin/false prometheus
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.50.1/prometheus-2.50.1.linux-amd64.tar.gz
tar -xvzf /tmp/prometheus-2.50.1.linux-amd64.tar.gz

mv prometheus /usr/local/bin
mv promtool /usr/local/bin
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

mv consoles /etc/prometheus
mv console_libraries /etc/prometheus
mv prometheus.yml /etc/prometheus

chown prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
chown -R prometheus:prometheus /var/lib/prometheus

cat <<EOT >> /lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOT

cat <<EOT >> /etc/prometheus/prometheus.yml
global:
  evaluation_interval: 5s
  external_labels:
    env: production
  scrape_interval: 30s

scrape_configs:
- job_name: prometheus
  scrape_interval: 5m
  static_configs:
  - targets:
    - localhost:9090

- job_name: slurm-exporter
  scrape_interval: 15s
  metrics_path: /metrics
  static_configs:
  - targets:
    - 'localhost:9092'

- job_name: grafana
  scrape_interval: 15s
  scrape_timeout: 5s
  static_configs: 
  - targets: 
    - "localhost:3000"
EOT

# Install prometheus-slurm-exporter
# >> Install go
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GO111MODULE=on

# >> clone repository
git clone https://github.com/rivosinc/prometheus-slurm-exporter.git /opt/prometheus-slurm-exporter

# >> build repository
cd /opt/prometheus-slurm-exporter
go install

# >> Create systemd file
cat <<EOT >> /lib/systemd/system/slurm-exporter.service
[Unit]
Description=Slurm Exporter Version latest
After=network-online.target
[Service]
User=slurm-exporter
Group=slurm-exporter
Type=simple
ExecStart=/opt/go/bin/prometheus-slurm-exporter -slurm.collect-diags
[Install]
WantedBy=multi-user.target
# >> Enable+start prometheus-slurm-exporter service
EOT


systemctl enable slurm-exporter
systemctl start slurm-exporter

systemctl enable prometheus
systemctl start prometheus

systemctl enable grafana-server
systemctl start grafana-server
