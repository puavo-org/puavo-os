require 'ffi'

module Puavo
    class Conf
        class Error < StandardError
        end

        extend FFI::Library
        begin
            ffi_lib '/usr/local/lib/libpuavoconf.so'
        rescue LoadError
            ffi_lib '/usr/lib/libpuavoconf.so'
        end

        attach_function :puavo_conf_init, [:pointer], :int
        attach_function :puavo_conf_free, [:pointer], :void
        attach_function :puavo_conf_open, [:pointer], :int
        attach_function :puavo_conf_close, [:pointer], :int
        attach_function :puavo_conf_set, [:pointer, :string, :string], :int
        attach_function :puavo_conf_get, [:pointer, :string, :pointer], :int
        attach_function :puavo_conf_errstr, [:pointer], :string

        def initialize
            puavoconf_p = FFI::MemoryPointer.new(:pointer)

            if puavo_conf_init(puavoconf_p) == -1 then
                raise Puavo::Conf::Error, 'Could not init puavo conf'
            end

            puavoconf = puavoconf_p.read_pointer
            puavoconf_p.free

            if puavo_conf_open(puavoconf) == -1 then
                raise Puavo::Conf::Error, puavo_conf_errstr(puavoconf)
            end

            @puavoconf = puavoconf
        end

        def get(key)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            value_p = FFI::MemoryPointer.new(:pointer)

            if puavo_conf_get(@puavoconf, key, value_p) == -1 then
                raise Puavo::Conf::Error, puavo_conf_errstr(@puavoconf)
            end

            value = value_p.read_pointer.read_string
            value_p.free

            return value
        end

        def set(key, value)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            if puavo_conf_set(@puavoconf, key.to_s, value.to_s) == -1 then
                raise Puavo::Conf::Error, puavo_conf_errstr(@puavoconf)
            end
        end

        def close
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            if puavo_conf_close(@puavoconf) == -1 then
                raise Puavo::Conf::Error, puavo_conf_errstr(@puavoconf)
            end
            puavo_conf_free(@puavoconf)
            @puavoconf = nil
        end
    end
end
