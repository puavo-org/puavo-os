class PuavoSharedDirectories
  def self.description(dirtype, lang, schoolname, groupname='')
    translations = {
      'en' => {
        'all'      => "All - #{ schoolname }",
        'base'     => "Share - #{ schoolname }",
        'group'    => "#{ groupname } - #{ schoolname }",
        'material' => "Material - #{ schoolname }",
        'programs' => "Programs - #{ schoolname }",
      },
      'fi' => {
        'all'      => "Kaikki - #{ schoolname }",
        'base'     => "Yhteiset - #{ schoolname }",
        'group'    => "#{ groupname } - #{ schoolname }",
        'material' => "Materiaali - #{ schoolname }",
        'programs' => "Ohjelmat - #{ schoolname }",
      },
      'sv' => {
        'all'      => "Allmän - #{ schoolname }",
        'base'     => "Delade Filer - #{ schoolname }",
        'group'    => "#{ groupname } - #{ schoolname }",
        'material' => "Material - #{ schoolname }",
        'programs' => "Program - #{ schoolname }",
      },
    }

    lookup_translation(translations, lang, dirtype)
  end

  def self.dirpath(basedir, dirtype, lang, name='')
    nicename = name.scan(/[[:alnum:]åäöÅÄÖ._-]/).join

    translations = {
      'en' => {
        'all'      => 'All',
        'base'     => 'share',
        'group'    => "#{ nicename }",
        'material' => 'Material',
        'programs' => 'Programs',
      },
      'fi' => {
        'all'      => 'Kaikki',
        'base'     => 'yhteiset',
        'group'    => "#{ nicename }",
        'material' => 'Materiaali',
        'programs' => 'Ohjelmat',
      },
      'sv' => {
        'all'      => 'Allmän',
        'base'     => 'delade_filer',
        'group'    => "#{ nicename }",
        'material' => 'Material',
        'programs' => 'Program',
      },
    }

    "#{ basedir }/#{ lookup_translation(translations, lang, dirtype) }"
  end

  def self.lookup_translation(translations, lang, key)
    raise 'Language not defined'          if lang.nil?
    raise 'Language not supported'        if translations[lang].nil?
    raise 'Translation key not supported' if translations[lang][key].nil?

    translations[lang][key]
  end
end
