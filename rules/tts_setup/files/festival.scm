(set! default_after_synth_hooks

          (list
            (lambda (utt)
              (utt.wave.rescale utt 0.9 t))))

(Parameter.set 'Audio_Required_Format'aiff)
(Parameter.set 'Audio_Command"paplay $FILE --client-name=Festival --stream-name=Speech")
(Parameter.set 'Audio_Method 'Audio_Command)
