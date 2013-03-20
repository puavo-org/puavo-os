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
        'all'      => 'share/All',
        'base'     => 'share',
        'group'    => "share/#{ nicename }",
        'material' => 'share/Material',
        'programs' => 'share/Programs',
      },
      'fi' => {
        'all'      => 'yhteiset/Kaikki',
        'base'     => 'yhteiset',
        'group'    => "yhteiset/#{ nicename }",
        'material' => 'yhteiset/Materiaali',
        'programs' => 'yhteiset/Ohjelmat',
      },
      'sv' => {
        'all'      => 'delade_filer/Allmän',
        'base'     => 'delade_filer',
        'group'    => "delade_filer/#{ nicename }",
        'material' => 'delade_filer/Material',
        'programs' => 'delade_filer/Program',
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
