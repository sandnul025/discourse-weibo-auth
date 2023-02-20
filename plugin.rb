enabled_site_setting :enable_weibo_login

gem('omniauth-weibo-oauth2', '0.5.2')

register_svg_icon "fab-weibo"

class WeiboAuthenticator < Auth::ManagedAuthenticator

  class WeiboStrategy < OmniAuth::Strategies::OAuth2

    option :name, 'weibo'

    option :client_options,
           site: 'https://api.weibo.com',
           authorize_url: 'oauth2/authorize',
           token_url: 'oauth2/access_token'

    uid do
      @uid ||= begin
                 access_token.params['openid']
               end
    end

    info do
      {
        :nickname => raw_info['nickname'],
        :name => raw_info['nickname'],
        :image => raw_info['headimgurl'],
      }
    end

    extra do
      {
        :raw_info => raw_info
      }
    end

    def raw_info
      @raw_info ||= begin
                      response = client.request(:get, "https://api.weixin.qq.com/sns/userinfo", :params => {
                        :openid => uid,
                        :access_token => access_token.token
                      }, :parse => :json)
                      response.parsed
                    end
    end

    def authorize_params
      super.tap do |params|
        params[:appid] = options.client_id
        params[:scope] = 'snsapi_login'
      end
    end

    def token_params
      super.tap do |params|
        params[:appid] = options.client_id
        params[:secret] = options.client_secret
        params[:parse] = :json
        params.delete('client_id')
        params.delete('client_secret')
      end
    end

  end

  def enabled?
    SiteSetting.enable_weibo_login?
  end

  def name
    'weibo'
  end

  def match_by_email
    false
  end

  def register_middleware(omniauth)
    omniauth.provider weiboStrategy,
                      setup: lambda { |env|
                        strategy = env['omniauth.strategy']
                        strategy.options[:client_id] = SiteSetting.weibo_client_id
                        strategy.options[:client_secret] = SiteSetting.weibo_secret
                      }
  end
end

auth_provider authenticator: WeiboAuthenticator.new, icon: 'fab-weibo'
