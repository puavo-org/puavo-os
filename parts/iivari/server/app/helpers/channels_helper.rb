module ChannelsHelper
  def themes
    [ [t('.gold'), 'gold'], [t('.green'), 'green'], [t('.cyan'), 'cyan'] ]
  end

  def channels
    Channel.with_permissions_to(:show).find_all_by_school_id(@school.puavo_id)
  end
end
