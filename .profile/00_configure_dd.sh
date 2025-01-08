#!/usr/bin/env bash

ruby .profile/support/configure_dd_for_postgres.rb
ruby .profile/support/configure_dd_for_elasticsearch.rb
ruby .profile/support/configure_dd_for_memcache.rb
