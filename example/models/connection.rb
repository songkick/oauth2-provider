require 'fileutils'

dbfile = File.expand_path('../../db/notes.sqlite3', __FILE__)
FileUtils.mkdir_p(File.dirname(dbfile))

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => dbfile)

