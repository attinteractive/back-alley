require 'rubygems'
require 'bundler'

Bundler.setup

$: << "./lib"

require 'sinatra'
require 'back-alley'

set :run, false

run BackAlley::Server