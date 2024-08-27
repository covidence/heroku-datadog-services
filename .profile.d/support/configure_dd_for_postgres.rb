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
      'ssl' => true,
      'dbname' => uri.path.split(/^[?\/]/).detect { |p| p && !p.empty? },
      'tags' => tags,
      'custom_queries' => [{
        'query' => 'SELECT id FROM public.references ORDER BY id DESC LIMIT 1',
        'columns' => [
          { 'name' => 'references_latest_id', 'type' => 'gauge' }
        ],
        'collection_interval' => 14_400 # 4 hours
      },
      {
        'query' => 'SELECT id FROM public.study_votes ORDER BY id DESC LIMIT 1',
        'columns' => [
          { 'name' => 'study_votes_latest_id', 'type' => 'gauge' }
        ],
        'collection_interval' => 14_400 # 4 hours
      }]

    # custom_queries:
    #   - query: SELECT foo, COUNT(*) FROM table.events GROUP BY foo
    #     columns:
    #     - name: foo
    #       type: tag
    #     - name: event.total
    #       type: gauge
    #     tags:
    #     - test:postgresql
    #     metric_prefix: postgresql

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
