Rails.application.routes.draw do
  # API v1
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Auth
      post "auth/send_verification_code", to: "auth#send_verification_code"
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/refresh", to: "auth#refresh"
      post "auth/reset_password", to: "auth#reset_password"

      # Topics
      resources :topics, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :search
        end
        member do
          post :cool, action: "topic_cool", controller: "interactions"
          delete :cool, action: "topic_uncool", controller: "interactions"
          post :tips, action: "tip", controller: "interactions"
        end

        # Comments
        resources :comments, only: [:index, :create, :destroy] do
          member do
            post :toggle_login_only
          end
        end

        # Polls (nested under topic for create/destroy)
        resource :poll, only: [:create, :destroy]
      end

      # Comments cool (standalone route)
      post "comments/:comment_id/cool", to: "interactions#comment_cool"
      delete "comments/:comment_id/cool", to: "interactions#comment_uncool"

      # Polls (standalone routes for vote/close/open)
      post "polls/:poll_id/vote", to: "polls#vote"
      post "polls/:poll_id/close", to: "polls#close"
      post "polls/:poll_id/open", to: "polls#open"

      # Users
      resources :users, only: [:show] do
        collection do
          get :search
        end
        member do
          post :follow
          delete :follow, action: "unfollow"
          post :block
          delete :block, action: "unblock"
        end
      end

      # Nodes
      resources :nodes, only: [:index] do
        member do
          post :follow
          delete :follow, action: "unfollow"
        end
      end

      # Profile
      resource :profile, only: [:show, :update] do
        patch :password
      end

      # Check-in
      resource :check_in, only: [:create]

      # Notifications
      resources :notifications, only: [:index] do
        collection do
          get :unread_count
          put :read_all
        end
        member do
          put :read
        end
      end

      # Images
      resources :images, only: [:create]

      # Misc
      get "chat_groups", to: "misc#chat_groups"
      get "site_info", to: "misc#site_info"
      get "friend_links", to: "misc#friend_links"
    end
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: "users/registrations", passwords: "users/passwords" }
  devise_scope :user do
    post "send_verification_code", to: "users/registrations#send_verification_code", as: "send_verification_code", defaults: { format: :json }
    post "send_password_reset_code", to: "users/passwords#send_verification_code", as: "send_password_reset_code", defaults: { format: :json }
    get "users/oauth_invitation_code", to: "users/omniauth_callbacks#oauth_invitation_code", as: "users_oauth_invitation_code"
    post "users/verify_oauth_invitation_code", to: "users/omniauth_callbacks#verify_oauth_invitation_code", as: "users_verify_oauth_invitation_code"
  end

  # Admin dashboard
  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index, :update ]
    resources :operational_accounts, only: [ :index, :destroy ] do
      collection do
        post :batch_generate
        get :export
      end
    end
    resources :nodes, except: [ :show ] do
      collection do
        post :reorder
      end
    end
    resources :friend_links, except: [ :show ] do
      patch :settings, on: :collection
    end
    resources :chat_groups, except: [ :show ]
    resources :invitation_codes, only: [ :index, :create, :destroy, :show ]
    get "settings", to: "settings#index"
    patch "settings", to: "settings#update"
    get "seo_settings", to: "seo_settings#index"
    patch "seo_settings", to: "seo_settings#update"
    get "appearance_settings", to: "appearance_settings#index"
    patch "appearance_settings", to: "appearance_settings#update"
  end

  # Chat Groups
  resources :chat_groups, only: [:index]

  # Topics
  resources :topics, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      post :pin
      post :unpin
    end
    resources :comments, only: [:create, :destroy] do
      member do
        post :toggle_login_only
      end
      resource :cool, controller: 'comment_cools', only: [:create, :destroy]
    end
    resource :cool, only: [:create, :destroy]
    resources :tips, only: [:create], defaults: { format: :json }
    resource :poll, only: [:create, :destroy] do
      member do
        post :vote, defaults: { format: :json }
        post :close
        post :open
      end
    end
  end
  get "nodes/:node/topics", to: "topics#index", as: :node_topics

  # Image upload
  post "upload_image", to: "images#create", as: :upload_image
  get "images/:id", to: "images#show", as: :uploaded_image

  # Notifications
  resources :notifications, only: [:index, :update] do
    patch :read_all, on: :collection
    get :unread_count, on: :collection, defaults: { format: :json }
  end

  # Check-in
  resource :check_in, only: [:create]

  # Profile
  resource :profile, only: [:show, :update]

  # User public profile
  get "users/:id", to: "users#show", as: :user

  # User search (for @mentions)
  get "users/search", to: "users#search", defaults: { format: :json }

  # Follows
  post "users/:id/follow", to: "follows#create", as: :follow_user
  delete "users/:id/follow", to: "follows#destroy", as: :unfollow_user

  # Blocks
  post "users/:id/block", to: "blocks#create", as: :block_user
  delete "users/:id/block", to: "blocks#destroy", as: :unblock_user

  # Node Follows
  post "nodes/:node_id/follow", to: "node_follows#create", as: :follow_node
  delete "nodes/:node_id/follow", to: "node_follows#destroy", as: :unfollow_node

  get "pages/home"
  get "search", to: "topics#search", as: :search
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: :xml }
  get "robots.txt", to: "application#robots", defaults: { format: :text }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Redirect legacy /nodes/:node/:id to /:node/:slug
  get "nodes/:node/:id", to: redirect { |params, req|
    topic = Topic.find_by(id: params[:id].to_i)
    topic ? "/#{params[:node]}/#{topic.slug}" : "/topics"
  }, status: :moved_permanently

  # Defines the root path route ("/")
  RESERVED_NODE_SLUGS = %w[topics users admin pages search notifications profile check_in images chat_groups sitemap robots nodes].freeze
  get ":node/:slug", to: "topics#show", as: :node_topic, constraints: ->(req) { !RESERVED_NODE_SLUGS.include?(req.params[:node]) }
  root "topics#index"
end
