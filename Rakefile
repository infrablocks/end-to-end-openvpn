require 'confidante'
require 'rake_terraform'
require 'rake_ssh'
require 'rake_easy_rsa'
require 'rake_gpg'
require 'rake_template'

configuration = Confidante.configuration

RakeTerraform.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'terraform'),
    version: '1.1.7')
RakeEasyRSA.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'easy-rsa'),
    version: '3.0.8')

RakeSSH.define_key_tasks(
    namespace: :cluster_key,
    path: 'config/secrets/cluster/',
    comment: 'maintainers@infrablocks.io')

namespace :bootstrap do
  RakeTerraform.define_command_tasks(
      configuration_name: 'bootstrap',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    t.source_directory = 'infra/bootstrap'
    t.work_directory = 'build'

    t.state_file =
        File.join(Dir.pwd, "state/bootstrap/#{args.deployment_identifier}.tfstate")

    t.vars = configuration
        .for_overrides(args)
        .for_scope(role: 'bootstrap')
        .vars
  end
end

namespace :domain do
  RakeTerraform.define_command_tasks(
      configuration_name: 'domain',
      argument_names: [:deployment_identifier, :domain_name]
  ) do |t, args|
    configuration = configuration
        .for_overrides(args)
        .for_scope(role: 'domain')

    t.source_directory = 'infra/domain'
    t.work_directory = 'build'

    t.backend_config = configuration.backend_config
    t.vars = configuration.vars
  end
end

namespace :network do
  RakeTerraform.define_command_tasks(
      configuration_name: 'network',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    configuration = configuration
        .for_overrides(args)
        .for_scope(role: 'network')

    t.source_directory = 'infra/network'
    t.work_directory = 'build'

    t.backend_config = configuration.backend_config
    t.vars = configuration.vars
  end
end

namespace :cluster do
  RakeTerraform.define_command_tasks(
      configuration_name: 'cluster',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    configuration = configuration
        .for_overrides(args)
        .for_scope(role: 'cluster')

    t.source_directory = 'infra/cluster'
    t.work_directory = 'build'

    t.backend_config = configuration.backend_config
    t.vars = configuration.vars
  end
end

namespace :service do
  RakeTerraform.define_command_tasks(
      configuration_name: 'service',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    deployment_configuration = configuration
        .for_overrides(args)
        .for_scope(role: 'service')

    t.source_directory = 'infra/service'
    t.work_directory = 'build'

    t.backend_config = deployment_configuration.backend_config
    t.vars = deployment_configuration.vars
  end
end

namespace :deployment do
  task :provision, [:deployment_identifier, :domain_name] do |_, args|
    deployment_identifier = args.deployment_identifier
    domain_name = args.domain_name

    Rake::Task['bootstrap:provision'].invoke(deployment_identifier)
    Rake::Task['domain:provision'].invoke(deployment_identifier, domain_name)
    Rake::Task['network:provision'].invoke(deployment_identifier)
    Rake::Task['cluster:provision'].invoke(deployment_identifier)
    Rake::Task['service:provision'].invoke(deployment_identifier)
  end

  task :destroy, [:deployment_identifier, :domain_name] do |_, args|
    deployment_identifier = args.deployment_identifier
    domain_name = args.domain_name

    Rake::Task['service:destroy'].invoke(deployment_identifier)
    Rake::Task['cluster:destroy'].invoke(deployment_identifier)
    Rake::Task['network:destroy'].invoke(deployment_identifier)
    Rake::Task['domain:destroy'].invoke(deployment_identifier, domain_name)
    Rake::Task['bootstrap:destroy'].invoke(deployment_identifier)
  end
end

namespace :pki do
  RakeEasyRSA.define_pki_tasks do |t|
    t.pki_directory = 'config/secrets/pki'
    t.common_name = 'InfraBlocks Example VPN'
    t.expires_in_days = 365
  end
end

namespace :template do
  RakeTemplate.define_render_task(
      argument_names: [:template_file_path, :output_file_path, :vars]
  ) do |t, args|
    t.template_file_path = args.template_file_path
    t.output_file_path = args.output_file_path
    t.vars = args.vars
  end
end

namespace :encryption do
  RakeGPG.define_encrypt_task(
      argument_names: [:key_file_path, :input_file_path, :output_file_path]
  ) do |t, args|
    t.key_file_path = args.key_file_path
    t.input_file_path = args.input_file_path
    t.output_file_path = args.output_file_path
  end
end

namespace :server do
  desc "Generate a server certificate and key for the VPN"
  task :generate, [:dns_address] do |_, args|
    Rake::Task['pki:server:create'].invoke(args.dns_address)
  end

  desc "Revoke a server certificate and key for the VPN"
  task :revoke, [:dns_address] do |_, args|
    Rake::Task['pki:certificate:revoke'].invoke(args.dns_address)
    Rake::Task['pki:crl:generate']
  end
end

namespace :client do
  desc "Add a user to the VPN"
  task :add, [:email_address,:dns_address] do |_, args|
    email_address = args.email_address
    dns_address = args.dns_address

    work_directory = 'build/openvpn'
    pki_directory = 'config/secrets/pki'
    openvpn_directory = 'config/secrets/openvpn'
    key_directory = 'config/gpg'

    ca_certificate_path = "#{pki_directory}/ca.crt"
    client_certificate_path = "#{pki_directory}/issued/#{email_address}.crt"
    client_key_path = "#{pki_directory}/private/#{email_address}.key"

    key_file_path =
        "#{key_directory}/#{email_address}.gpgkey"
    client_ovpn_template_path =
        'config/templates/client.ovpn.erb'
    client_ovpn_rendered_path =
        "#{work_directory}/#{email_address}.ovpn"
    client_ovpn_encrypted_path =
        "#{openvpn_directory}/#{email_address}.ovpn.gpg"

    Rake::Task['pki:client:create'].invoke(email_address)
    Rake::Task['template:render']
        .invoke(
            client_ovpn_template_path,
            client_ovpn_rendered_path,
            ca_certificate: read_certificate(ca_certificate_path),
            client_certificate: read_certificate(client_certificate_path),
            client_key: read_key(client_key_path),
            dns_address: dns_address)
    Rake::Task['encryption:encrypt']
        .invoke(
            key_file_path,
            client_ovpn_rendered_path,
            client_ovpn_encrypted_path)

    File.unlink(client_ovpn_rendered_path)
  end

  desc "Remove a user from the VPN"
  task :remove, [:email_address] do |_, args|
    email_address = args.email_address

    openvpn_directory = 'config/secrets/openvpn'
    client_ovpn_encrypted_path =
        "#{openvpn_directory}/#{email_address}.ovpn.gpg"

    Rake::Task['pki:certificate:revoke'].invoke(email_address)
    Rake::Task['pki:crl:generate']
    File.unlink(client_ovpn_encrypted_path)
  end
end

def read_certificate(path)
  File.read(path)
      .split("\n")
      .drop_while { |l| l !~ /BEGIN CERTIFICATE/ }
      .join("\n")
end

def read_key(path)
  File.read(path)
      .strip
end
