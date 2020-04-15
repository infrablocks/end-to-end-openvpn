require 'confidante'
require 'rake_terraform'
require 'rake_docker'
require 'rake_ssh'

require_relative 'lib/terraform_output'
require_relative 'lib/version'

configuration = Confidante.configuration
version = Version.from_file('build/version')

RakeTerraform.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'terraform'),
    version: '0.12.17')

RakeSSH.define_key_tasks(
    namespace: :cluster_key,
    path: 'config/secrets/cluster/',
    comment: 'maintainers@infrablocks.io')

namespace :bucket do
  RakeTerraform.define_command_tasks(
      configuration_name: 'state bucket',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    t.source_directory = 'infra/state_bucket'
    t.work_directory = 'build'

    t.state_file =
        File.join(Dir.pwd, "state/state_bucket/#{args.deployment_identifier}.tfstate")

    t.vars = configuration
        .for_overrides(args)
        .for_scope(role: 'state-bucket')
        .vars
  end
end

namespace :domain do
  RakeTerraform.define_command_tasks(
      configuration_name: 'domain',
      argument_names: [:deployment_identifier, :domain_name]
  ) do |t, args|
    t.source_directory = 'infra/domain'
    t.work_directory = 'build'

    t.backend_config = configuration
        .for_overrides(args)
        .for_scope(role: 'domain')
        .backend_config

    t.vars = configuration
        .for_overrides(args)
        .for_scope(role: 'domain')
        .vars
  end
end

namespace :network do
  RakeTerraform.define_command_tasks(
      configuration_name: 'network',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    t.source_directory = 'infra/network'
    t.work_directory = 'build'

    t.backend_config = configuration
        .for_overrides(args)
        .for_scope(role: 'network')
        .backend_config

    t.vars = configuration
        .for_overrides(args)
        .for_scope(role: 'network')
        .vars
  end
end

namespace :cluster do
  RakeTerraform.define_command_tasks(
      configuration_name: 'cluster',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    t.source_directory = 'infra/cluster'
    t.work_directory = 'build'

    t.backend_config configuration
        .for_overrides(args)
        .for_scope(
            role: 'cluster')
        .backend_config

    t.vars = configuration
        .for_overrides(args)
        .for_scope(role: 'cluster')
        .vars
  end
end

namespace :services do
  RakeTerraform.define_command_tasks(
      configuration_name: 'concourse services',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    deployment_identifier = args.deployment_identifier
    concourse_config = YAML.load_file(
        "config/secrets/concourse/web/#{deployment_identifier}.yaml")
    database_config = YAML.load_file(
        "config/secrets/database/#{deployment_identifier}.yaml")
    deployment_configuration = configuration
        .for_overrides(
            args.to_hash
                .merge(database_config)
                .merge(concourse_config)
                .merge(version_number: version.to_docker_tag))
        .for_scope(role: 'services')


    t.source_directory = 'infra/services'
    t.work_directory = 'build'

    t.backend_config = deployment_configuration.backend_config
    t.vars = deployment_configuration.vars
  end
end
