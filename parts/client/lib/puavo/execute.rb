require 'open3'

module Puavo

  class ExitStatusError < StandardError
    attr_accessor :response

    def initialize(response_object)
      @response = response_object
    end
  end

  class RubyVersionError < StandardError; end

  class Response
    attr_accessor :stdout, :stderr, :exit_status
  end

  #
  # Puavo::Execute.run is helper method for running shell program. Raise error if exit status is not 0.
  #
  # == Simple Examples
  #
  #   # run method returns a response object with methods stdout, stderr and exit_status
  #   response = Puavo::Execute.run(["echo", "Hello World"])
  #   puts response.stdout
  #
  #   # Raise error (Puavo::ExitStatusError) if exit status is not 0
  #   # response method of exception returns a response object.
  #   begin
  #     Puavo::Execute.run(["false"])
  #   rescue Puavo::ExitStatusError => exception
  #     puts exception.response.exit_status.to_s
  #   end
  #
  class Execute

    def self.run(command_and_args)

      response = Response.new

      Open3.popen3(*command_and_args) do |stdin, stdout, stderr, wait_thr|
        if wait_thr.nil?
          raise( RubyVersionError,
                 "Probably you are using an older version of the Ruby. Method not support Ruby 1.8." )
        end

        response.stdout = stdout.read
        response.stderr = stderr.read
        response.exit_status = wait_thr.value.exitstatus
      end

      if response.exit_status != 0
        raise ExitStatusError.new(response), response.stderr
      end

      return response

    end
  end
end
