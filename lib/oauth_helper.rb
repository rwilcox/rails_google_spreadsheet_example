module  OauthHelper

  def self.default(key)
    p = (RAILS_ROOT + '/config/defaults.yml')
    YAML::load(ERB.new( IO.read(p)).result)[key]
  end


  # Heroku uses config settings / env variables for secret stuff
  # see <http://docs.heroku.com/config-vars>
  #
  # But we won't assume you're on Heroku all the time: if the env is
  # undefined we look for a file named config/defaults.yml
  #
  # This function looks for OAUTH_CONSUMER_KEY env variable / key in yaml
  def self.consumer_key
    ENV["OAUTH_CONSUMER_KEY"] || default("OAUTH_CONSUMER_KEY")
  end

  # like the above function, but uses OAUTH_CONSUMER_SECRET
  # as key
  def self.consumer_secret
    ENV["OAUTH_CONSUMER_SECRET"] || default("OAUTH_CONSUMER_SECRET")
  end
end