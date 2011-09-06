Iivari::Application.routes.draw do
  resources :school_admin_groups, :path => ':school_id/admins' do
    collection do
      put(':group_id',
          :to => 'school_admin_groups#add_group',
          :as => 'add_group' )
      delete(':group_id',
          :to => 'school_admin_groups#delete_group',
          :as => 'delete_group' )
    end
  end
  resources :displays, :path => ':school_id/displays'

  match '/channels/welcome', :to => "channels#welcome", :as => 'welcome'
  resources :channels, :path => ':school_id/channels' do
    resources :slides do
      post :sort, :on => :collection
      member do
        put :toggle_status
        get :slide_status
      end
    end
  end

  resources :slides, :path => ':school_id/slides' do
    resources :slide_timers
  end

  match '/slides/new/:template', :to => "slides#new", :as => 'template_new_slide'

  match 'conductor', :to => "screen#conductor", :as => "conductor_screen"
  match 'slides.json', :to => "screen#slides", :format => :json, :as => "conductor_slides"
  match 'image/:template/:image', :to => "screen#image", :as => "image_screen"
  match 'displayauth', :to => "screen#displayauth", :as => "display_authentication"
  match "screen.manifest", :to => "screen#manifest", :as => "manifest_screen"

  resources :user_sessions

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "channels#welcome"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
