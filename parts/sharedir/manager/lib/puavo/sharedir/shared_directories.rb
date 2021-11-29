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
        'returnbox' => "Rückgabeordner - #{ schoolname }",
      },
      'en' => {
        'all'       => "All - #{ schoolname }",
        'base'      => "Share - #{ schoolname }",
        'group'     => "#{ groupname } - #{ schoolname }",
        'material'  => "Material - #{ schoolname }",
        'programs'  => "Programs - #{ schoolname }",
        'returnbox' => "Return Box - #{ schoolname }",
      },
      'fi' => {
        'all'       => "Kaikki - #{ schoolname }",
        'base'      => "Yhteiset - #{ schoolname }",
        'group'     => "#{ groupname } - #{ schoolname }",
        'material'  => "Materiaali - #{ schoolname }",
        'programs'  => "Ohjelmat - #{ schoolname }",
        'returnbox' => "Palautuslaatikko - #{ schoolname }",
      },
      'sv' => {
        'all'       => "Allmän - #{ schoolname }",
        'base'      => "Delade Filer - #{ schoolname }",
        'group'     => "#{ groupname } - #{ schoolname }",
        'material'  => "Material - #{ schoolname }",
        'programs'  => "Program - #{ schoolname }",
        'returnbox' => "Återlämningslåda - #{ schoolname }",
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
        'returnbox' => 'Rückgabeordner',
      },
      'en' => {
        'all'       => 'All',
        'base'      => 'share',
        'material'  => 'Material',
        'programs'  => 'Programs',
        'returnbox' => 'Return Box',
      },
      'fi' => {
        'all'       => 'Kaikki',
        'base'      => 'yhteiset',
        'material'  => 'Materiaali',
        'programs'  => 'Ohjelmat',
        'returnbox' => 'Palautuslaatikko',
      },
      'sv' => {
        'all'       => 'Allmän',
        'base'      => 'delade_filer',
        'material'  => 'Material',
        'programs'  => 'Program',
        'returnbox' => 'Återlämningslåda',
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
