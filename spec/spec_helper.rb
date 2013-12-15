require 'rubygems'
require 'bundler/setup'

require 'random_attributes'

RSpec.configure do |config|
  config.order = 'random'
end
