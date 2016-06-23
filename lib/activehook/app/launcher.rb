module ActiveHook
  module App
    # Handles the start of the ActiveHook web via command line
    #
    class Launcher
      def initialize(argv)
        @argv = argv
        @puma_config = nil
      end

      def start
        start_message
        setup_options
        boot_puma
      end

      private

      def start_message
        ActiveHook.log.info('ActiveHook App starting!')
        ActiveHook.log.info("* Version #{VERSION}, codename: #{CODENAME}")
      end

      # Parses the arguments passed through the command line.
      #
      def setup_options
        parser = OptionParser.new do |o|
          o.banner = 'Usage: bundle exec bin/activehook [options]'

          o.on('-c', '--config PATH', 'Load PATH for config file') do |arg|
            load(arg)
            ActiveHook.log.info("* App config:  #{arg}")
          end

          o.on('-p', '--puma config PATH', 'Load PATH for puma config file') do |arg|
            @puma_config = arg
            ActiveHook.log.info("* Puma config: #{arg}")
          end

          o.on('-h', '--help', 'Prints this help') { puts o && exit }
        end
        parser.parse!(@argv)
      end

      def boot_puma
        ActiveHook.log.info('* Booting Puma...')
        exec("bundle exec puma -C #{@puma_config} --dir lib/activehook/app/")
      end
    end
  end
end
