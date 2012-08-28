module Songkick
  module OAuth2
    
    class Schema
      def self.up
        ActiveRecord::Base.logger ||= Logger.new(StringIO.new)
        load_migrations
        ActiveRecord::Migrator.up(migrations_path)
      end
      
      def self.migrations_path
        File.expand_path('../schema', __FILE__)
      end
      
      def self.load_migrations
        Dir.entries(migrations_path).each do |file|
          path = File.join(migrations_path, file)
          require(path) if File.file?(path)
        end
        constants.each do |const_name|
          Object.const_set(const_name, const_get(const_name))
        end
      end
    end
    
  end
end

