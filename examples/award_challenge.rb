#!/usr/bin/env ruby
require 'rubygems'
require 'nitro_api'

settings = JSON.parse(File.read('keys.json'))

nitro = NitroApi::NitroApi.new 1, settings['key'], settings['secret']

nitro.login
nitro.award_challenge "Watch 5 Hours of Video"

progress = nitro.challenge_progress "Watch 5 Hours of Video"
puts "#{progress['name']} completed count:#{progress['completionCount']}"
