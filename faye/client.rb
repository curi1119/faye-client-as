# This script demonstrates a logger for the chat app. First, start the chat
# server in one terminal then run this in another:
#
#   $ ruby examples/ruby/server.rb
#   $ ruby examples/ruby/client.rb
#
# The client connects to the chat server and logs all messages sent by all
# connected users.

require 'rubygems'
require 'bundler/setup'
require 'faye'

endpoint = "http://localhost:9300/faye"

EM.run {
  puts "Connecting to #{endpoint}"
  client = Faye::Client.new(endpoint)
  client.connect

  # subscription = client.subscribe '/chat/*' do |message|
  #   user = message['user']

  #   publication = client.publish("/members/#{ user }", {
  #     "user"    => "ruby-logger",
  #     "message" => "Got your message, #{ user }!"
  #   })
  #   publication.callback do
  #     puts "[PUBLISH SUCCEEDED]"
  #   end
  #   publication.errback do |error|
  #     puts "[PUBLISH FAILED] #{error.inspect}"
  #   end
  # end

  # subscription.callback do
  #   puts "[SUBSCRIBE SUCCEEDED]"
  # end
  # subscription.errback do |error|
  #   puts "[SUBSCRIBE FAILED] #{error.inspect}"
  # end

  # client.bind 'transport:down' do
  #   puts "[CONNECTION DOWN]"
  # end
  # client.bind 'transport:up' do
  #   puts "[CONNECTION UP]"
  # end
}
