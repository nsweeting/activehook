require 'activehook/server'

module ActiveHook
  class CLI
    def initialize(argv)
      setup_options(argv)
    end

    def start
      server = ActiveHook::Server.new
      server.start
    end

    private

    def setup_options(argv)
      parser = OptionParser.new do |o|
        o.banner = 'Usage: bundle exec bin/activehook [options]'

        o.on('-c', '--config PATH', 'Load PATH for config file') do |arg|
          load(arg)
          ActiveHook.log.info("Loaded configuration from #{arg}")
        end

        o.on('-h', '--help', 'Prints this help') do
          puts o && exit
        end
      end
      parser.parse!(argv)
    end
  end
end
