#cloud-config

write_files:
  - path: /run/awsconfig
    content: |
      [default]
      region = ${region}
      output = json
      role_arn = ${admin}
      credential_source = Ec2InstanceMetadata
      [profile ${profile}]
      region = ${region}
      output = json
      role_arn = ${admin}
      credential_source = Ec2InstanceMetadata
runcmd:
  - [mkdir, "/home/${user}/.aws"]
  - [chown, "ubuntu:ubuntu", /home/${user}/.aws]
  - [mv, "/run/awsconfig", "/home/${user}/.aws/config"]
  - [chown, "ubuntu:ubuntu", /home/${user}/.aws/config]

