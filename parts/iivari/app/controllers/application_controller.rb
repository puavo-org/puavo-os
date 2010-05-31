class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'

  I18n.locale = :fi
end
