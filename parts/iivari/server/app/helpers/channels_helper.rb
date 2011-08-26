module ChannelsHelper
  def themes
    [ [t('.gold'), 'gold'], [t('.green'), 'green'], [t('.cyan'), 'cyan'] ]
  end

  def channels
    Channel.with_permissions_to(:manage).all
  end
end
