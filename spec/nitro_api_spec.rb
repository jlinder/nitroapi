require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe NitroApi do
  before do
    @user = "user"
    @api_key = "key"
    @secret = "secret"
    @nitro = NitroApi::NitroApi.new @user, @api_key, @secret
    @nitro.protocol = 'http'
    @success = {"Nitro" => {"res" => "ok"}}.to_json
    @session = "1"
  end

  describe "#sign" do
    it "takes MD5 like in http://wiki.bunchball.com/w/page/12748060/user_login" do
      ts = Time.now.utc.to_i.to_s
      to_digest = @api_key + @secret +  ts + @user.to_s
      to_digest += to_digest.length.to_s
      @nitro.sign(ts).should  == Digest::MD5.hexdigest(to_digest)
    end
  end

  describe "#login" do
    it "should set session id for a successful call" do
      mock_json = {"Nitro" => {"Login" => {"sessionKey" => @session}}}
      url = @nitro.base_url + "?.*method=user.login.*"
      p url
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
        url = @nitro.base_url + "?.*method=user.logAction.*"
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
        url = @nitro.base_url + "?.*method=user.logAction.*"
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => @success)

        @nitro.log_action actions
      end
    end

    describe "#challenge_progress" do
      before do
        params = {
          "showOnlyTrophies" => "false",
          "sessionKey" => @session,
          "method" => "user.getChallengeProgress"
        }
        url = @nitro.base_url + "?.*method=user.getChallengeProgress.*"
        mock_rules = {"goal" => "1", "type" => "none", "completed" => "false",
          "actionTag" => "action"}

        mock_data = [{"completionCount"=>"1",
          "description" => "some description",
          "name" => "Watch 10 Videos",
          "rules" => {"Rule" => mock_rules}}]

        mock_json = {"Nitro" => {"challenges" => {"Challenge" => mock_data}}}
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => mock_json.to_json)

        response = @nitro.challenge_progress
        @challenge = response[0]
      end

      it "returns the challenge part of the response" do
        @challenge.should_not be_nil
        @challenge.description.should == "some description"
        @challenge.completed.should == 1
      end

      it "has rules in the challenge" do
        @challenge.rules.should_not be_empty
        @challenge.rules.size.should == 1
        rule = @challenge.rules.first
        rule.type.should == :none
        rule.completed.should be_false
        rule.action.should == "action"
        rule.goal.should == 1
      end
    end

    describe "#award challenge" do
      it "returns the challenge part of the response" do
        params = {
          "userId" => @user,
          "sessionKey" => @session,
          "challenge" => "TestChallenge",
          "method" => "user.awardChallenge"
        }
        url = @nitro.base_url + "?.*method=user.awardChallenge.*"
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => @success)

        @nitro.award_challenge "TestChallenge"
      end
    end

    describe "#action_history" do
      before do
        @now = Time.now
        @mock_history =
         [
          {'ts' => @now.to_i, 'tags' => 'action0', 'value' => '0'},
          {'ts' => @now.to_i, 'tage' => 'action1', 'value' => '1'}
         ]
        @mock_json = {"Nitro" =>
          {"ActionHistoryRecord" =>
            {"ActionHistoryItem" => @mock_history}}}.to_json
      end

      it "returns an array of log entries with date & value for all actions" do
        params = {
          "sessionKey" => @session,
          "method" => "user.getActionHistory"
        }
        url = @nitro.base_url + "?.*method=user.getActionHistory.*"
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => @mock_json)

        history = @nitro.action_history
        history.count.should == 2
        history[0][:tags].should == 'action0'
        history[0][:ts].to_i.should == @now.to_i
        history[1][:value].should == 1
      end

      it "can ask for history for a specific action list" do
        params = {
          "sessionKey" => @session,
          "method" => "user.getActionHistory",
          "tags" => "action1"
        }
        url = @nitro.base_url + "?.*method=user.getActionHistory.*"
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => @mock_json)

        @nitro.action_history 'action1'
      end
    end

    describe "#join_group name_of_group" do
      it "sends that user joined a group" do
        params = {"groupName" => "group",
          "sessionKey" => @session,
          "method" => "user.joinGroup"
        }
        url = @nitro.base_url + "?.*method=user.joinGroup.*"
        stub_http_request(:get, Regexp.new(url)).
          with(:query => params).
          to_return(:body => @success)

        @nitro.join_group "group"
      end      
    end
  end
end
