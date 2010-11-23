require 'rubygems'
require 'active_record'

dir = File.expand_path(File.dirname(__FILE__))

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => dir + '/../db/notes.sqlite3')

