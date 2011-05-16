dir = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler'

Bundler.require
require 'oauth2/provider'
require 'fileutils'

require dir + '/models/connection'

FileUtils.mkdir_p(dir + '/db')

ActiveRecord::Schema.define do |version|
  create_table :users, :force => true do |t|
    t.timestamps
    t.string :username
  end

  create_table :notes, :force => true do |t|
    t.timestamps
    t.belongs_to :user
    t.string     :title
    t.text       :body
  end
end

OAuth2::Model::Schema.up

