;; WARNING: It is inherently insecure to run a festival instance as a
;; server, mainly because it exposes the whole system to exploits which
;; can be easily used by attackers to gain access to your
;; computer. This is because of the inherent design of the festival
;; server. Please use it only in a situation where you are sure that
;; you will not be subjected to such an attack, or have adequate
;; security precautions.

;; This file has been provided as an example file for your use, should
;; you wish to run festival as a server.

; Maximum number of clients on the server
;(set! server_max_clients 10)

; Server port
;(set! server_port 1314)

; Server password:
;(set! server_passwd "password")

; Log file location
;(set! server_log_file "/var/log/festival/festival.log")

; Server access list (hosts)
; Example:
; (set! server_access_list '("[^.]+" "127.0.0.1" "localhost.*" "192.168.*"))
; Secure default:
;(set! server_access_list '("[^.]+" "127.0.0.1" "localhost"))

; Server deny list (hosts)

(set! default_after_synth_hooks
          (list
            (lambda (utt)
              (utt.wave.rescale utt 0.9 t))))

(if (probe_file "/usr/share/festival/voices/finnish/suopuhe.common/hy_fi_mv_diphone.scm")
    (begin
     (load "/usr/share/festival/voices/finnish/suopuhe.common/hy_fi_mv_diphone.scm")
     (set! voice_default 'hy_fi_mv_diphone)))

(Parameter.set 'Audio_Required_Format'aiff)
(Parameter.set 'Audio_Command"paplay $FILE --client-name=Festival --stream-name=Speech")
(Parameter.set 'Audio_Method 'Audio_Command)
