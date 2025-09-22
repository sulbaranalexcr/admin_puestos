# frozen_string_literal: true

require_relative 'config/environment'
include ApplicationHelper
require 'net/http'
require 'net/https'
require 'rufus-scheduler'


ENV['TZ'] = 'America/Caracas'
scheduler = Rufus::Scheduler.new
@task_in_progress = false

scheduler.every '2s' do
  puts "entre"
  puts "no continuo porque estoy ocupado" if @task_in_progress
  next if @task_in_progress
  

  puts "continuo bien"

  @task_in_progress = true
  # Thread.new { 
    alex(SecureRandom.hex(10))
  # }
  @task_in_progress = false
rescue StandardError => e 
  @task_in_progress = false
end


def alex(vari)
  puts "entre #{vari}"
  sleep 30
  puts "termine #{vari}"
end

scheduler.join
