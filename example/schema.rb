require 'rubygems'
require 'bundler/setup'

require 'songkick/oauth2/provider'
require 'active_record'
require File.expand_path('../models/connection', __FILE__)

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

Songkick::OAuth2::Model::Schema.up

