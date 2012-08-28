module Songkick
  module OAuth2
    
    class Schema
      def self.up
        ActiveRecord::Base.logger ||= Logger.new(StringIO.new)
        ActiveRecord::Migrator.up(migrations_path)
      end
      
      def self.migrations_path
        File.expand_path('../schema', __FILE__)
      end
    end
    
  end
end

