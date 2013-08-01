module TestApp

  class User < ActiveRecord::Base
    self.table_name = :users

    include Songkick::OAuth2::Model::ResourceOwner
    include Songkick::OAuth2::Model::ClientOwner

    def self.[](name)
      if respond_to?(:find_or_create_by)
        find_or_create_by(:name => name)
      else
        find_or_create_by_name(name)
      end
    end
  end

  module Helper
    module RackRunner
      def start(port)
        handler = Rack::Handler.get('thin')
        Thread.new do
          handler.run(new, :Port => port) { |server| @server = server }
        end
        sleep 0.1 until @server
      end

      def stop
        @server.stop if @server
        @server = nil
        sleep 0.1 while EM.reactor_running?
      end
    end
  end

end

