#!/usr/bin/env ruby

require 'uri'
require 'net/https'
require 'yaml'
require 'fileutils'

instances = []

def get(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth(uri.user, uri.password)
  http.request(request)
end

ENV.keys.grep(/_URL$/).each do |key|
  uri = URI(ENV[key]) rescue next

  tags = ENV["#{key}_TAGS"].to_s.split(/\s+/)

  if uri.scheme =~ /^https?/
    resp = get(uri + '/_cluster/health')

    if resp.code.to_i / 100 == 2
      username, password = uri.user, uri.password
      uri.user = nil
      uri.password = nil
      puts "Configuring Datadog for ElasticSearch: #{uri}"

      instances << {
        'url' => uri.to_s,
        'username' => username,
        'password' => password,
        'cluster_stats' => true,
        'index_stats' => true,
        'pshard_stats' => true,
        'tags' => tags,
      }
    end
  end
end

if instances.any?
  FileUtils.mkdir_p('/app/datadog/conf.d/')
  File.open('/app/datadog/conf.d/elastic.yaml', 'w') do |f|
    f.write YAML.dump({
      'init_config' => nil,
      'instances' => instances
    })
  end
end
