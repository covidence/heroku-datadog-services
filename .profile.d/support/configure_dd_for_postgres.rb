#!/usr/bin/env ruby

require 'uri'
require 'yaml'
require 'fileutils'

instances = []

ENV.keys.grep(/_URL$/).each do |key|
  uri = URI(ENV[key]) rescue next
  tags = ENV["#{key}_TAGS"].to_s.split(/\s+/)

  if uri.scheme =~ /^postgres/
    puts "Configuring Datadog for Postgres: #{uri.to_s.gsub(uri.userinfo, '****:****')}"

    tags << "host:#{uri.host}"

    instances << {
      'host' => uri.host,
      'port' => uri.port,
      'username' => uri.user,
      'password' => uri.password,
      'ssl' => 'allow',
      'dbname' => uri.path.split(/^[?\/]/).detect { |p| p && !p.empty? },
      'tags' => tags,
      # Example https://github.com/DataDog/integrations-core/blob/master/postgres/datadog_checks/postgres/data/conf.yaml.example
      'custom_queries' => [{
        'metric_prefix' => 'postgresql',
        'query' => 'SELECT id FROM public.references ORDER BY id DESC LIMIT 1',
        'columns' => [
          { 'name' => 'references_latest_id', 'type' => 'gauge' }
        ]
      },
      {
        'metric_prefix' => 'postgresql',
        'query' => 'SELECT id FROM public.study_votes ORDER BY id DESC LIMIT 1',
        'columns' => [
          { 'name' => 'study_votes_latest_id', 'type' => 'gauge' }
        ]
      }]
    }
  end
end

if instances.any?
  FileUtils.mkdir_p('/app/datadog/conf.d/')
  File.open('datadog/conf.d/postgres.yaml', 'w') do |f|
    f.write YAML.dump({
      'init_config' => nil,
      'instances' => instances
    })
  end
end
