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
