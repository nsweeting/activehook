require 'activehook/server'

module ActiveHook
  class CLI
    class << self
      def run(argv)
        setup_options(argv)
        ActiveHook::Server.run
      end

      private

      def setup_options(argv)
        parser = OptionParser.new do |o|
          o.banner = 'Usage: bundle exec bin/activehook [options]'
          o.on('-c', '--config PATH', 'Load PATH for config file') do |arg|
            load(arg)
          end
          o.on('-h', '--help', 'Prints this help') do
            puts o && exit
          end
        end
        parser.parse!(argv)
      end
    end
  end
end
