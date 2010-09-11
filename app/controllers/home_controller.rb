require 'lib/oauth_helper'
require 'oauth'
require "google_spreadsheet"

# This controller uses OAuth to authorize (this app) to access a user's data.
# Some credit where credit is due: <http://runerb.com/2010/01/12/ruby-oauth-youtube/>
# essentially saved my bacon on this, telling me (almost) exactly what I needed
# to do.
class HomeController < ApplicationController
  before_filter :get_gs_session, :only => [:index, :new_spreadsheet, :create_spreadsheet]

  def index
    @spreadsheets = []
    unless @gs_session.nil?
      @spreadsheets = @gs_session.spreadsheets
    end
  end


  def new_spreadsheet
  end


  def create_spreadsheet
    created_sheet = @gs_session.create_spreadsheet(params[:spreadsheet_name])
    target_worksheet = created_sheet.worksheets[0]
    target_worksheet[1, 1] = "hello"
    target_worksheet[1, 2] = "world"
    target_worksheet[1, 3] = "we are from Ruby!"
    target_worksheet.save()

    flash[:notice] = "Successfully created #{params[:spreadsheet_name]}"
    redirect_to "/"
  end


  # Step 1 in the OAuth process... (get request token)
  def oauth_get_request_token
    scope = "https://docs.google.com/feeds/ https://spreadsheets.google.com/feeds/"
    # need two scopes to create new documents. Yes, these are separated by a space
    # and no they do not need to be URL encoded. WD-rpw 09-07-2010

    request_token = consumer.get_request_token(
      {:oauth_callback => "http://#{request.host}/oauth_request_authorized" },
      {:scope => scope}
    )

    request_token.token          # The request token itself
    request_token.secret         # The request tokens' secret
    session[:oauth_secret] = request_token.secret
    # Redirect back to Google for auth
    redirect_to request_token.authorize_url
    
    #request_token.authorize_url  # The authorization URL at Google
  end


  # Step 2 in the OAuth process: get the request token
  def oauth_request_authorized
    # Recreate the (now authorized) request token
    request_token = OAuth::RequestToken.new(consumer, 
        params[:oauth_token],
        session[:oauth_secret]
    )

    # Swap the authorized request token for an access token                                        
    access_token = request_token.get_access_token(
                       {:oauth_verifier => params[:oauth_verifier]})

    # Save the token and secret to the session
    # We use these to recreate the access token
    session[:oauth_token] = access_token.token
    session[:oauth_secret] = access_token.secret
    redirect_to "/"
  end

  def plain_login
    session[:username] = params[:username]
    session[:password] = params[:password]
    redirect_to "/"
  end

  def logout
    clear_session
    redirect_to "/"
  end

private
  def consumer
    OAuth::Consumer.new(OauthHelper::consumer_key, OauthHelper::consumer_secret, {
      :site=>"https://www.google.com", 
      :request_token_path=>"/accounts/OAuthGetRequestToken",
      :authorize_path=>"/accounts/OAuthAuthorizeToken",
      :access_token_path=>"/accounts/OAuthGetAccessToken"}
    )
  end


  # Step 3 in the OAuth process: create an access token
  # Once we have the oauth token and oauth secret from the RequestToken
  # we can create an AccessToken
  def access_token
    if session[:oauth_token] && session[:oauth_secret]
      @access_token ||= OAuth::AccessToken.new(
          consumer, 
          session[:oauth_token], 
          session[:oauth_secret]
      )
    end
  end


  def get_gs_session
    access_token
    if @access_token
      @gs_session = GoogleSpreadsheet.login_with_oauth( @access_token )
    end

    if session[:username] && session[:password]
      @gs_session = GoogleSpreadsheet.login( session[:username], session[:password] )
    end
  end


  def clear_session
    session[:username] = nil
    session[:password] = nil
    session[:oauth_token] = nil
    session[:oauth_secret] = nil
  end
end
