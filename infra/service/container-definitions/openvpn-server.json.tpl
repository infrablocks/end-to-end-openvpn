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
      { "name": "S3_BUCKET_REGION", "value": "$${region}" },
      { "name": "ENV_FILE_S3_OBJECT_PATH", "value": "${env_file_object_path}" }
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
