module Puavo
    class Puavoconf
        extend FFI::Library
        ffi_lib '/usr/lib/libpuavoconf.so'

        attach_function :puavo_conf_init, [], :pointer
        attach_function :puavo_conf_free, [:pointer], :void
        attach_function :puavo_conf_open_db, [:pointer, :string], :int
        attach_function :puavo_conf_close_db, [:pointer], :int
        attach_function :puavo_conf_set, [:pointer, :string, :string], :int
        attach_function :puavo_conf_get, [:pointer, :string], :string

        def initialize
            puavoconf = puavo_conf_init()
            if puavoconf.nil? then
                raise 'Could not init puavo conf'
            end

            if puavo_conf_open_db(puavoconf, '/tmp/puavoconf.db') == -1 then
                raise 'Could not open puavoconf database'
            end

            @puavoconf = puavoconf
        end

        def get(key)
            raise 'Puavodb is not open' unless @puavoconf

            return puavo_conf_get(key)
        end

        def set(key, value)
            raise 'Puavodb is not open' unless @puavoconf

            if puavo_conf_set(@puavoconf, key.to_s, value.to_s) == -1 then
                raise 'Error setting a value to puavoconf database'
            end

            return
        end

        def close
            raise 'Puavodb is not open' unless @puavoconf

            ret = puavo_conf_close_db(@puavoconf)
            puavo_conf_free(@puavoconf)
            @puavoconf = nil

            if ret == -1 then
                raise 'Error closing a puavoconf database'
            end
        end
    end
end
