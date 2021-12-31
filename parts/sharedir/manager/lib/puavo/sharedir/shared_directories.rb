# -*- coding: utf-8 -*-

class PuavoSharedDirectories
  def self.description(dirtype, lang, schoolname, groupname='')
    translations = {
      'de' => {
        'all'       => "Alle - #{ schoolname }",
        'base'      => "Geteilt - #{ schoolname }",
        'group'     => "#{ groupname } - #{ schoolname }",
        'material'  => "Material - #{ schoolname }",
        'programs'  => "Programme - #{ schoolname }",
        'returnbox' => "Abgabeordner - #{ schoolname }",
        'returns'   => "Eingesammelte Aufgaben - #{ schoolname }",
      },
      'en' => {
        'all'       => "All - #{ schoolname }",
        'base'      => "Share - #{ schoolname }",
        'group'     => "#{ groupname } - #{ schoolname }",
        'material'  => "Material - #{ schoolname }",
        'programs'  => "Programs - #{ schoolname }",
        'returnbox' => "Assigment Submission Box - #{ schoolname }",
        'returns'   => "Collected Assignments - #{ schoolname }",
      },
      'fi' => {
        'all'       => "Kaikki - #{ schoolname }",
        'base'      => "Yhteiset - #{ schoolname }",
        'group'     => "#{ groupname } - #{ schoolname }",
        'material'  => "Materiaali - #{ schoolname }",
        'programs'  => "Ohjelmat - #{ schoolname }",
        'returnbox' => "Palautuslaatikko - #{ schoolname }",
        'returns'   => "Kerätyt palautukset - #{ schoolname }",
      },
      'sv' => {
        'all'       => "Allmän - #{ schoolname }",
        'base'      => "Delade Filer - #{ schoolname }",
        'group'     => "#{ groupname } - #{ schoolname }",
        'material'  => "Material - #{ schoolname }",
        'programs'  => "Program - #{ schoolname }",
        'returnbox' => "Inlämningslåda - #{ schoolname }",
        'returns'   => "Insamlade inlämningar - #{ schoolname }",
      },
    }

    lookup_translation(translations, lang, dirtype)
  end

  def self.detox(toxic)
    toxic.force_encoding("UTF-8").scan(/[[:alnum:]åäöÅÄÖ._-]/).join
  end

  def self.dirname(dirtype, lang)
    translations = {
      'de' => {
        'all'       => 'Alle',
        'base'      => 'geteilt',
        'material'  => 'Material',
        'programs'  => 'Programme',
        'returnbox' => 'Abgabeordner',
        'returns'   => 'Eingesammelte Aufgaben',
      },
      'en' => {
        'all'       => 'All',
        'base'      => 'share',
        'material'  => 'Material',
        'programs'  => 'Programs',
        'returnbox' => 'Assignment Submission Box',
        'returns'   => 'Collected Assignments',
      },
      'fi' => {
        'all'       => 'Kaikki',
        'base'      => 'yhteiset',
        'material'  => 'Materiaali',
        'programs'  => 'Ohjelmat',
        'returnbox' => 'Palautuslaatikko',
        'returns'   => 'Kerätyt palautukset',
      },
      'sv' => {
        'all'       => 'Allmän',
        'base'      => 'delade_filer',
        'material'  => 'Material',
        'programs'  => 'Program',
        'returnbox' => 'Inlämningslåda',
        'returns'   => 'Insamlade inlämningar',
      },
    }

    lookup_translation(translations, lang, dirtype)
  end

  def self.lookup_translation(translations, lang, key)
    raise 'Language not defined'          if lang.nil?
    raise 'Language not supported'        if translations[lang].nil?
    raise 'Translation key not supported' if translations[lang][key].nil?

    translations[lang][key]
  end
end
