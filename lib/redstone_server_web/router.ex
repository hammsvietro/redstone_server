defmodule RedstoneServerWeb.Router do
  use RedstoneServerWeb, :router

  import RedstoneServerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {RedstoneServerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_user
  end

  scope "/", RedstoneServerWeb.Html do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", RedstoneServerWeb.Api do
    pipe_through :api
    post "/login", UserAuth, :login
  end

  ## Authentication routes

  scope "/api", RedstoneServerWeb.Api do
    pipe_through [:api, :require_authenticated_user_api]
    get "/auth_test", UserAuth, :test_auth
    delete "/log_out", UserAuth, :logout

    scope "/upload" do
      post "/declare", Upload, :declare_backup
      post "/push", Upload, :push
    end

    scope "/download" do
      post "/clone", Download, :clone
      post "/pull", Download, :pull
    end

    scope "/update" do
      get "/fetch/:backup_id", Update, :fetch
    end
  end

  scope "/", RedstoneServerWeb.Html do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", RedstoneServerWeb.Html do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", RedstoneServerWeb.Html do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
