class AppResponder < ActionController::Responder
  include Responders::FlashResponder
  include Responders::HttpCacheResponder
end
