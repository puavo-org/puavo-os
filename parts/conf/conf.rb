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
        attach_function :puavo_conf_open_db, [:pointer, :pointer], :int
        attach_function :puavo_conf_close_db, [:pointer], :int
        attach_function :puavo_conf_set, [:pointer, :string, :string], :int
        attach_function :puavo_conf_get, [:pointer, :string, :pointer], :int

        def initialize
            puavoconf_p = FFI::MemoryPointer.new(:pointer)

            if puavo_conf_init(puavoconf_p) == -1 then
                raise Conf::Error, 'Could not init puavo conf'
            end

            puavoconf = puavoconf_p.read_pointer
            puavoconf_p.free

            if puavo_conf_open_db(puavoconf, FFI::Pointer::NULL) == -1 then
                raise Conf::Error, 'Could not open puavoconf database'
            end

            @puavoconf = puavoconf
        end

        def get(key)
            raise Conf::Error, 'Puavodb is not open' unless @puavoconf

            value_p = FFI::MemoryPointer.new(:pointer)

            if puavo_conf_get(@puavoconf, key, value_p) == -1 then
                raise Conf::Error,
                      'Error getting a value from puavoconf database'
            end

            value = value_p.read_pointer.read_string
            value_p.free

            return value
        end

        def set(key, value)
            raise Conf::Error, 'Puavodb is not open' unless @puavoconf

            if puavo_conf_set(@puavoconf, key.to_s, value.to_s) == -1 then
                raise Conf::Error,
                      'Error setting a value to puavoconf database'
            end
        end

        def close
            raise Conf::Error, 'Puavodb is not open' unless @puavoconf

            ret = puavo_conf_close_db(@puavoconf)
            puavo_conf_free(@puavoconf)
            @puavoconf = nil

            if ret == -1 then
                raise Conf::Error, 'Error closing a puavoconf database'
            end
        end
    end
end
