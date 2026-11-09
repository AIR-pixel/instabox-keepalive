set -e
cat > /tmp/dsh-web.service <<'UNIT'
[Unit]
Description=DSH web headless (WorkBuddy shim host)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=user
WorkingDirectory=/data/home
Environment=HOME=/data/home
EnvironmentFile=/data/home/site/.env
Environment=DSH_HOME=/data/home/.dsh
ExecStart=/usr/local/bin/dsh web --no-open --port 3080 --public-url https://3000-agqxbsiqvgwynvjjh2k5auu4au.instabox.tech/dsh/ --trusted-host 3000-agqxbsiqvgwynvjjh2k5auu4au.instabox.tech
StandardOutput=append:/data/home/site/dsh-web.log
StandardError=append:/data/home/site/dsh-web.log
Restart=always
RestartSec=5
KillMode=mixed
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
UNIT
sudo install -m 644 /tmp/dsh-web.service /etc/systemd/system/dsh-web.service
sudo systemctl daemon-reload
sudo systemctl restart dsh-web
for i in $(seq 1 20); do
  sleep 2
  if ss -ltn 2>/dev/null | grep -q ':3080 '; then break; fi
done
echo "active: $(systemctl is-active dsh-web)"
ls -l /data/home/site/dsh-web.log 2>/dev/null | awk '{print "log bytes:",$5}'
grep -o 'token=[A-Za-z0-9_-]\{20,\}' /data/home/site/dsh-web.log 2>/dev/null | tail -1
