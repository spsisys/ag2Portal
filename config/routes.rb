Ag2Portal::Application.routes.draw do
  scope "(:locale)", :locale => /en|es/ do
    # Get for index pages
    get "icores/index"
    get "lowres/index"
    get "home/index"
    
    # Devise (the standard route is: devise_for :users) localized
    devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

    # PaperTrail versioning
    post "versions/:id/revert" => "versions#revert", :as => "revert_version"

    # Routes for jQuery POSTs
    match 'oco_company_organization_from_office/:office', :controller => 'oco', :action => 'oco_company_organization_from_office'
    match 'oco_organization_from_company/:company', :controller => 'oco', :action => 'oco_organization_from_company'
    match 'oco_set_session/:office/:company/:organization', :controller => 'oco', :action => 'oco_set_session'
        
    # Root
    root :to => "welcome#index"
  
    # Engines
    mount Ag2Admin::Engine => "/ag2_admin"
    mount Ag2Directory::Engine => "/ag2_directory"
    mount Ag2Human::Engine => "/ag2_human"
    mount Ag2HelpDesk::Engine => "/ag2_help_desk"
    mount Ag2Purchase::Engine => "/ag2_purchase"
    mount Ag2Products::Engine => "/ag2_products"
    mount Ag2Tech::Engine => "/ag2_tech"
    mount Ag2Gest::Engine => "/ag2_gest"
  end

  # Index locale
  # match '/:locale' => 'welcome#index'

  # get "welcome/index"
    
  # devise_for :users

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
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
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
  #       get 'recent', :on => :collection
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
  # root :to => "welcome#index"
  
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
