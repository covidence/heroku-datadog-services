#!/usr/bin/env ruby

require 'uri'
require 'yaml'
require 'fileutils'

instances = []

ENV.keys.grep(/_URL$/).each do |key|
  uri = URI(ENV[key]) rescue next
  tags = ENV["#{key}_TAGS"].to_s.split(/\s+/)

  if uri.scheme =~ /^postgres/
    puts "Configuring Postgres for ElasticSearch: #{uri.to_s.gsub(uri.userinfo, '****:****')}"

    instances << {
      'host' => uri.host,
      'port' => uri.port,
      'username' => uri.user,
      'password' => uri.password,
      'ssl' => true,
      'dbname' => uri.path.split(/^[?\/]/).detect { |p| p && !p.empty? },
      'tags' => tags,
    }
  end
end

if instances.any?
  FileUtils.mkdir_p('datadog/conf.d/postgres.d/')
  File.open('datadog/conf.d/postgres.d/conf.yaml', 'w') do |f|
    f.write YAML.dump({
      'init_config' => nil,
      'instances' => instances
    })
  end
end
