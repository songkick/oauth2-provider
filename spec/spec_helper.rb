dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'rubygems'
require 'oauth2/provider'
require 'test_apps/provider/application'
require 'uri'
require 'cgi'
require 'net/http'

require 'thin'
Thin::Logging.silent = true

