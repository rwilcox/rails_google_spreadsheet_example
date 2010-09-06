require 'lib/oauth_helper'
require 'oauth'

class HomeController < ApplicationController
  
  def index
    consumer_key = OauthHelper::consumer_key
  end

  # Step 1 in the OAuth process...
  def oauth_get_request_token
    scope = "https://spreadsheets.google.com/feeds/"
    consumer = OAuth::Consumer.new(OauthHelper::consumer_key, OauthHelper::consumer_secret, {
      :site=>"https://www.google.com", 
      :request_token_path=>"/accounts/OAuthGetRequestToken",
      :authorize_path=>"/accounts/OAuthAuthorizeToken",
      :access_token_path=>"/accounts/OAuthGetAccessToken"})

    request_token = consumer.get_request_token(
      {:oauth_callback => "#{request.host}/oauth_request_authorized" },
      {:scope => scope}
    )

    request_token.token          # The request token itself
    request_token.secret         # The request tokens' secret
    session[:oauth_secret] = request_token.secret
    # Redirect back to Google for auth
    redirect_to request_token.authorize_url
    
    #request_token.authorize_url  # The authorization URL at Google
  end

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

end
