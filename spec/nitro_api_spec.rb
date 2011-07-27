require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe NitroApi do
  before do
    @user = "user"
    @api_key = "key"
    @secret = "secret"
    @nitro = NitroApi::NitroApi.new @user, @api_key, @secret
  end

  describe "#sign" do
    it "takes MD5 like in http://wiki.bunchball.com/w/page/12748060/user_login" do
      to_digest = @api_key + @secret +  Time.now.utc.to_i.to_s + @user.to_s
      to_digest += to_digest.length.to_s
      @nitro.sign.should  == Digest::MD5.hexdigest(to_digest)
    end
  end

  describe "#login" do
    it "should set session id for a successful call" do
      mock_session = "1"
      mock_json = {"Nitro" => {"Login" => {"sessionKey" => mock_session}}}
      url = NitroApi::HOST + "?.*method=user.login.*"
      stub_http_request(:get, Regexp.new(url)).
        to_return(:body => mock_json.to_json)

      @nitro.login
      @nitro.session.should == mock_session
    end
  end
end
