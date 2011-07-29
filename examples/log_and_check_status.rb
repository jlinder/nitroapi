#!/usr/bin/env ruby
require 'rubygems'
require 'nitro_api'

settings = JSON.parse(File.read('keys.json'))

nitro = NitroApi::NitroApi.new 1, settings['key'], settings['secret']

nitro.login
nitro.log_action "Video_Watch"
nitro.challenge_progress
