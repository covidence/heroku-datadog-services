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
        ],
        'collection_interval' => 14_400 # 4 hours
      },
      {
        'metric_prefix' => 'postgresql',
        'query' => 'SELECT id FROM public.study_votes ORDER BY id DESC LIMIT 1',
        'columns' => [
          { 'name' => 'study_votes_latest_id', 'type' => 'gauge' }
        ],
        'collection_interval' => 14_400 # 4 hours
      },
      {
        # Getting table size metrics to monitor
        'metric_prefix' => 'postgresql',
        'query' => 'SELECT table_name, total_bytes, index_bytes, coalesce(toast_bytes, 0) as toast_bytes, table_bytes
                    FROM (
                    SELECT *, total_bytes-index_bytes-coalesce(toast_bytes,0) AS table_bytes FROM (
                        SELECT c.oid,nspname AS table_schema, relname AS table_name
                                , c.reltuples AS row_estimate
                                , pg_total_relation_size(c.oid) AS total_bytes
                                , pg_indexes_size(c.oid) AS index_bytes
                                , pg_total_relation_size(reltoastrelid) AS toast_bytes
                            FROM pg_class c
                            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                            WHERE relkind = \'r\'
                    ) a
                  ) a',
        'columns' => [
          { 'name' => 'table_name', 'type' => 'tag' },
          { 'name' => 'total_bytes', 'type' => 'gauge' },
          { 'name' => 'index_bytes', 'type' => 'gauge' },
          { 'name' => 'toast_bytes', 'type' => 'gauge' },
          { 'name' => 'table_bytes', 'type' => 'gauge' },
        ],
        'collection_interval' => 14_400 # 4 hours
      }]
    }
  end
end

if instances.any?
  FileUtils.mkdir_p('/app/datadog/conf.d/postgres.d')
  File.open('datadog/conf.d/postgres.d/conf.yaml', 'w') do |f|
    f.write YAML.dump({
      'init_config' => nil,
      'instances' => instances
    })
  end
end
