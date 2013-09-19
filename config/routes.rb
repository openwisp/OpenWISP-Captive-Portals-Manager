Railscp::Application.routes.draw do

  match 'api/v1/account/login' => "api#login", :as => :api_login
  match 'api/v1/account/logout' => "api#logout", :as => :api_logout
  match 'api/v1/account/status' => "api#status", :as => :api_status

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
  # match ':controller(/:action(/:id(.:format)))'

  resources :operator_sessions
  resources :captive_portals do
    resources :allowed_traffics
    resources :local_users
    resources :online_users
  end

  match 'operator/login'  => "operator_sessions#new",     :as => :operator_login
  match 'operator/logout' => "operator_sessions#destroy", :as => :operator_logout

  match 'application/set_session_locale'


  match 'redirect' => 'redirections#redirect', :as => :redirect, :method => :get
  match 'authentication' => 'redirections#default_authentication_page',
        :as => :authentication, :method => :get
  match 'error' => 'redirections#default_error_page',
        :as => :error, :method => :get
  match 'login' => 'redirections#login', :as => :login, :method => :post
  match 'logout' => 'redirections#logout', :as => :logout, :method => :get

  match '/' => "redirections#redirect"
  match '*path' => "redirections#redirect"

end