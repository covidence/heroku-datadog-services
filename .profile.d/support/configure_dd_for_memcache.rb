#!/usr/bin/env ruby

require 'uri'
require 'net/https'
require 'yaml'
require 'fileutils'

instances = []

ENV.keys.grep(/_SERVERS$/).each do |key|
  host, port = ENV[key].split(',').first.split(':')
  port ||= 11211
  username = ENV[key.sub(/_SERVERS/, '_USERNAME')]
  password = ENV[key.sub(/_SERVERS/, '_PASSWORD')]

  tags = ENV["#{key}_TAGS"].to_s.split(/\s+/)

  puts "Configuring Datadog for Memcache: #{ENV[key]}"

  instances << {
    'url' => host,
    'username' => username,
    'password' => password,
    'port' => port.to_i,
    'tags' => tags,
  }
end

if instances.any?
  FileUtils.mkdir_p('/app/datadog/conf.d/mcache.d')
  File.open('/app/datadog/conf.d/mcache.d/conf.yaml', 'w') do |f|
    f.write YAML.dump({
      'init_config' => nil,
      'instances' => instances
    })
  end
end
