[
  {
    "name": "$${name}",
    "image": "$${image}",
    "memoryReservation": 256,
    "memory": 512,
    "essential": true,
    "privileged": true,
    "command": $${command},
    "portMappings": [
      {
        "containerPort": ${container_port},
        "hostPort": ${host_port}
      }
    ],
    "environment": [
      { "name": "AWS_S3_BUCKET_REGION", "value": "$${region}" },
      { "name": "AWS_S3_ENV_FILE_OBJECT_PATH", "value": "${env_file_object_path}" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "$${log_group}",
        "awslogs-region": "$${region}"
      }
    }
  }
]
