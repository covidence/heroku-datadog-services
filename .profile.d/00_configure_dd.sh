#!/usr/bin/env bash

ruby .profile.d/support/configure_dd_for_postgres.rb
ruby .profile.d/support/configure_dd_for_elasticsearch.rb
ruby .profile.d/support/configure_dd_for_memcache.rb
