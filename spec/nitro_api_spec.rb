require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe NitroApi do
  before do
    @user = "user"
    @api_key = "key"
    @secret = "secret"
    @nitro = NitroApi::NitroApi.new @user, @api_key, @secret
    @success = {"Nitro" => {"res" => "ok"}}.to_json
    @session = "1"
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
      mock_json = {"Nitro" => {"Login" => {"sessionKey" => @session}}}
      url = NitroApi::HOST + "?.*method=user.login.*"
      stub_http_request(:get, Regexp.new(url)).
        to_return(:body => mock_json.to_json)

      @nitro.login
      @nitro.session.should == @session
    end
  end

  context "when authenticated" do
    before do
      @nitro.session = @session
    end

    describe "#log_action" do
      it "sends one action with session on query string" do
        action_name = "action"
        params = {"tags" => action_name,
          "sessionKey" => @session,
          "method" => "user.logAction"
        }
        url = NitroApi::HOST + "?.*method=user.logAction.*"
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => @success)

        @nitro.log_action action_name
      end

      it "sends comma seperated action list with session on query string" do
        actions = ["action1", "action2"]
        params = {"tags" => actions.join(","),
          "sessionKey" => @session,
          "method" => "user.logAction"
        }
        url = NitroApi::HOST + "?.*method=user.logAction.*"
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => @success)

        @nitro.log_action actions
      end
    end

    describe "#challenge_progress" do
      it "returns the challenge part of the response" do
        params = {
          "showOnlyTrophies" => "false",
          "sessionKey" => @session,
          "method" => "user.getChallengeProgress"
        }
        url = NitroApi::HOST + "?.*method=user.getChallengeProgress.*"
        mock_data = "challenge"
        mock_json = {"Nitro" => {"challenges" => {"Challenge" => mock_data}}}
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => mock_json.to_json)

        @nitro.challenge_progress.should == mock_data
      end
    end
  end
end
