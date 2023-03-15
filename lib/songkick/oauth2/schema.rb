module Songkick
  module OAuth2

    class Schema
      def self.migrate
        ActiveRecord::Base.logger ||= Logger.new(StringIO.new)
        ActiveRecord::MigrationContext.new(migrations_path, ActiveRecord::Base.connection.schema_migration).migrate
      end
      class << self
        alias :up :migrate
      end

      def self.rollback
        ActiveRecord::Base.logger ||= Logger.new(StringIO.new)
        ActiveRecord::Migrator.down(migrations_path)
      end
      class << self
        alias :down :rollback
      end

      def self.migrations_path
        File.expand_path('../schema', __FILE__)
      end
    end

  end
end

