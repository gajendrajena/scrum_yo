require 'highline/import'
require 'netrc'

module ScrumYo
  class User
    attr_reader :bitbucket_client, :username, :emails

    def initialize
      # Uses credentials in .netrc to authenticate
      @bitbucket_client = Octokit::Client.new(netrc: true)
      @username = @bitbucket_client.login
      @emails = @bitbucket_client.emails
    end

    def self.authenticate(logged_in = false)
      netrc = Netrc.read

      if netrc['https://bitbucket.org/api/2.0'] && Octokit::Client.new(netrc: true).login
        return true
      end

      puts "Authentication failed".red if logged_in

      get_credentials
    end

    def self.get_credentials
      puts "Please login with your bitbucket account.".yellow
      username = ask("bitbucket Username:")
      password = ask('Password (typing hidden):') { |q| q.echo = false }

      client = Octokit::Client.new(login: username, password: password)


      if agree('Do you use Two Factor Auth? (y/n)')
        two_factor = ask('Enter your 2FA token:')
        oauth = client.create_authorization(scopes: ['user','repo'], note: 'ScrumYo gem!', headers: { "X-bitbucket-OTP" => two_factor })
      else
        oauth = client.create_authorization(scopes: ['user','repo'], note: 'ScrumYo gem!')
      end

      save_to_netrc(username, oauth.token)
      self.authenticate(true)
    end

    def self.save_to_netrc(user, token)
      netrc = Netrc.read
      netrc.new_item_prefix = "# This entry was added by the ScrumYo gem\n"
      netrc['https://bitbucket.org/api/2.0'] = user, token
      netrc.save
    end

  end
end
