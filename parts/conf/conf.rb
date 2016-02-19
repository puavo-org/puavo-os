require 'ffi'

module Puavo
    class ConfErr < FFI::Struct
        layout  :errnum, :int,
      :db_error, :int,
      :sys_errno, :int,
      :msg, [:char, 1024]
    end

    class Conf
        class Error < StandardError
        end

        extend FFI::Library
        begin
            ffi_lib '/usr/local/lib/libpuavoconf.so'
        rescue LoadError
            ffi_lib '/usr/lib/libpuavoconf.so'
        end

        attach_function(:puavo_conf_open,   [:pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_close,  [:pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_set,    [:pointer, :string, :string, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_get,    [:pointer, :string, :pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_add,    [:pointer, :string, :pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_overwrite, [:pointer, :string, :pointer, ConfErr.by_ref],
                        :int)

        def initialize
            puavoconf_p = FFI::MemoryPointer.new(:pointer)
            conf_err = ConfErr.new

            if puavo_conf_open(puavoconf_p, conf_err) == -1 then
                raise Puavo::Conf::Error, conf_err[:msg].to_ptr.read_string
            end

            puavoconf = puavoconf_p.read_pointer
            puavoconf_p.free

            @puavoconf = puavoconf
        end

        def get(key)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            value_p = FFI::MemoryPointer.new(:pointer)
            conf_err = ConfErr.new

            if puavo_conf_get(@puavoconf, key, value_p, conf_err) == -1 then
                raise Puavo::Conf::Error, conf_err[:msg].to_ptr.read_string
            end

            value = value_p.read_pointer.read_string
            value_p.free

            return value
        end

        def set(key, value)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            conf_err = ConfErr.new

            if puavo_conf_set(@puavoconf, key.to_s, value.to_s, conf_err) == -1 then
                raise Puavo::Conf::Error, conf_err[:msg].to_ptr.read_string
            end
        end

        def close
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            conf_err = ConfErr.new

            if puavo_conf_close(@puavoconf, conf_err) == -1 then
                raise Puavo::Conf::Error, conf_err[:msg].to_ptr.read_string
            end
            @puavoconf = nil
        end

        def add(key, value)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            conf_err = ConfErr.new

            if puavo_conf_add(@puavoconf, key.to_s, value.to_s, conf_err) == -1 then
                raise Puavo::Conf::Error, conf_err[:msg].to_ptr.read_string
            end
        end

        def overwrite(key, value)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            conf_err = ConfErr.new

            if puavo_conf_overwrite(@puavoconf, key.to_s, value.to_s, conf_err) == -1 then
                raise Puavo::Conf::Error, conf_err[:msg].to_ptr.read_string
            end
        end

    end
end
