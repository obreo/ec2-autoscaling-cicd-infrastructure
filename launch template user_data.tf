# Write the content to  userdata-main.sh file
resource "local_file" "userdata_main" {
  count    = var.Docker_Application == true ? 0 : 1
  filename = "scripts/userdata-main.sh"
  content  = <<EOF
#!/bin/bash
# Userdata is used to set the following:
# Nginx configuration with the application port that it will redirect traffic to.
# Cloudwatch logs and metrics configuration data.
# Add Application runtime (NodeJS) on start up.
# Calling SSM Parameters

echo 'Retrieving SSM parameters'
# Create directory and move to it - just in case not available
if [ ! -d "/var/webapp" ]; then
    sudo mkdir -p /var/webapp
fi

cd /var/webapp

aws ssm get-parameters-by-path --path "${var.Main_PARAMETERS_PATH}" --with-decryption --query "Parameters[*].[Name,Value]" --output text 2>> /var/log/error.log | while read -r name value; do export_string="$${name##*/}=$value"; echo "$export_string" >> /var/webapp/.env; done


# Setting nginx configuration to listen to port 80 and edirect to application port:
cat << 'END' | sudo tee /etc/nginx/conf.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # Production environment
    location / {
        proxy_pass http://localhost:${var.application_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
END

# Setting CloudWatch Agent config
sudo cat >> /opt/aws/amazon-cloudwatch-agent/bin/config.json <<END
{
    "agent": {
            "metrics_collection_interval": 60,
            "run_as_user": "root"
    },
    "logs": {
            "logs_collected": {
                    "files": {
                            "collect_list": [
                                    {
                                            "file_path": "/var/log/error.log",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/error.log",
                                            "retention_in_days": 1
                                    },
                                    {
                                            "file_path": "/var/log/nginx/error.log",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/nginx/error.log",
                                            "retention_in_days": 1
                                    },
                                    {
                                            "file_path": "/var/log/nginx/access.log",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/nginx/access.log",
                                            "retention_in_days": 1
                                    },
                                    {
                                            "file_path": "/opt/codedeploy-agent/deployment-root/deployment-logs",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/codedeploy-agent-deployment",
                                            "retention_in_days": 1
                                    }
                            ]
                    }
            }
    },
    "metrics": {
            "aggregation_dimensions": [
                    [
                            "InstanceId"
                    ]
            ],
            "append_dimensions": {
                    "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}",
                    "ImageId": "\$${aws:ImageId}",
                    "InstanceId": "\$${aws:InstanceId}",
                    "InstanceType": "\$${aws:InstanceType}"
            },
            "metrics_collected": {
                    "disk": {
                            "measurement": [
                                    "used_percent"
                            ],
                            "metrics_collection_interval": 60,
                            "resources": [
                                    "*"
                            ]
                    },
                    "mem": {
                            "measurement": [
                                    "mem_used_percent"
                            ],
                            "metrics_collection_interval": 60
                    },
                    "statsd": {
                            "metrics_aggregation_interval": 60,
                            "metrics_collection_interval": 60,
                            "service_address": ":8125"
                    }
            }
    }
}
END

# Starting CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Make application runner start in the background automatically on restart using systemd service file
sudo bash -c 'cat <<END > /etc/systemd/system/myapp.service
[Unit]
Description=My Node.js App
After=network.target

[Service]
ExecStart=/usr/bin/npm start
WorkingDirectory=/var/webapp
Restart=always
User=ec2-user
Environment=PATH=/usr/bin:/usr/local/bin

[Install]
WantedBy=multi-user.target
END'

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable myapp
#sudo systemctl start myapp
systemctl restart nginx

# Logging setup
sudo systemctl status myapp > /var/log/myapp-status.log
EOF
}


# Write the content to  userdata-main.sh file
resource "local_file" "userdata_staging" {
  count    = var.Docker_Application == true ? 0 : 1
  filename = "scripts/userdata-staging.sh"
  content  = <<EOF
#!/bin/bash
# Userdata is used to set the following:
# Nginx configuration with the application port that it will redirect traffic to.
# Cloudwatch logs and metrics configuration data.
# Add Application runtime (NodeJS) on start up.
# Call SSM parameters

echo 'Retrieving SSM parameters'
# Create directory and move to it - just in case not available
if [ ! -d "/var/webapp" ]; then
    sudo mkdir -p /var/webapp
fi

cd /var/webapp

aws ssm get-parameters-by-path --path "${var.Staging_PARAMETERS_PATH}" --with-decryption --query "Parameters[*].[Name,Value]" --output text 2>> /var/log/error.log | while read -r name value; do export_string="$${name##*/}=$value"; echo "$export_string" >> /var/webapp/.env; done

# Setting nginx configuration to listen to port 80 and edirect to application port:
cat << 'END' | sudo tee /etc/nginx/conf.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # Production environment
    location / {
        proxy_pass http://localhost:${var.application_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
END

# Setting CloudWatch Agent config
sudo cat >> /opt/aws/amazon-cloudwatch-agent/bin/config.json <<END
{
    "agent": {
            "metrics_collection_interval": 60,
            "run_as_user": "root"
    },
    "logs": {
            "logs_collected": {
                    "files": {
                            "collect_list": [
                                    {
                                            "file_path": "/var/log/error.log",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/error.log",
                                            "retention_in_days": 1
                                    },
                                    {
                                            "file_path": "/var/log/nginx/error.log",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/nginx/error.log",
                                            "retention_in_days": 1
                                    },
                                    {
                                            "file_path": "/var/log/nginx/access.log",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/nginx/access.log",
                                            "retention_in_days": 1
                                    },
                                    {
                                            "file_path": "/opt/codedeploy-agent/deployment-root/deployment-logs",
                                            "log_group_name": "myapp/log/",
                                            "log_stream_name": "{instance_id}/codedeploy-agent-deployment",
                                            "retention_in_days": 1
                                    }
                            ]
                    }
            }
    },
    "metrics": {
            "aggregation_dimensions": [
                    [
                            "InstanceId"
                    ]
            ],
            "append_dimensions": {
                    "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}",
                    "ImageId": "\$${aws:ImageId}",
                    "InstanceId": "\$${aws:InstanceId}",
                    "InstanceType": "\$${aws:InstanceType}"
            },
            "metrics_collected": {
                    "disk": {
                            "measurement": [
                                    "used_percent"
                            ],
                            "metrics_collection_interval": 60,
                            "resources": [
                                    "*"
                            ]
                    },
                    "mem": {
                            "measurement": [
                                    "mem_used_percent"
                            ],
                            "metrics_collection_interval": 60
                    },
                    "statsd": {
                            "metrics_aggregation_interval": 60,
                            "metrics_collection_interval": 60,
                            "service_address": ":8125"
                    }
            }
    }
}
END

# Starting CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Make application runner start in the background automatically on restart using systemd service file
sudo bash -c 'cat <<END > /etc/systemd/system/myapp.service
[Unit]
Description=My Node.js App
After=network.target

[Service]
ExecStart=/usr/bin/npm start
WorkingDirectory=/var/webapp
Restart=always
User=ec2-user
Environment=PATH=/usr/bin:/usr/local/bin

[Install]
WantedBy=multi-user.target
END'

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable myapp
#sudo systemctl start myapp
systemctl restart nginx

# Logging setup
sudo systemctl status myapp > /var/log/myapp-status.log
EOF
}


