module ActiveHook
  class << self
    STDOUT.sync = true

    def log
      @log ||= Log.new
    end
  end

  class Log
    def initialize
      @log = Logger.new(STDOUT)
      @log.formatter = proc do |_severity, datetime, _progname, msg|
        "[ #{datetime} ] #{msg}\n"
      end
    end

    def info(msg)
      @log.info("[ \e[32mOK\e[0m ] #{msg}")
    end

    def err(msg, action: :no_exit)
      @log.info("[ \e[31mER\e[0m ] #{msg}")
      exit 1 if action == :exit
    end
  end
end
