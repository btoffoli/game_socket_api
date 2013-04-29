# encoding: UTF-8

require 'rubygems'
#require 'bundler/setup'
#require 'active_record'
#ActiveRecord::Base.establish_connection YAML::load(IO.read 'db/config.yml')[ENV['ENV'] || 'development']
Dir['./base/**/*.rb'].each{|m| require m}
Dir['./domain/**/*.rb'].each{|m| require m}
# call some useful code here
