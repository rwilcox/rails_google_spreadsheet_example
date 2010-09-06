require 'lib/oauth_helper'
require 'oauth'
require "google_spreadsheet"

class HomeController < ApplicationController
  
  def index
    @spreadsheets = []
    if session[:oauth_token]
      gs_session = GoogleSpreadsheet.login_with_oauth( session[:oauth_token] )
      @oauth_token = session[:oauth_token]
      @spreadsheets = gs_session.spreadsheets
    end
  end

  # Step 1 in the OAuth process... (get request token)
  def oauth_get_request_token
    scope = "https://spreadsheets.google.com/feeds/"

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


  # Step 2 in the OAuth process: get the access token
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

private
  def consumer
    OAuth::Consumer.new(OauthHelper::consumer_key, OauthHelper::consumer_secret, {
      :site=>"https://www.google.com", 
      :request_token_path=>"/accounts/OAuthGetRequestToken",
      :authorize_path=>"/accounts/OAuthAuthorizeToken",
      :access_token_path=>"/accounts/OAuthGetAccessToken"}
    )
  end
  
end
