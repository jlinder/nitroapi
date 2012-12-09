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
      stub_http_request(:get, Regexp.new(url)).
        to_return(:body => mock_json.to_json)

      @nitro.login
      @nitro.session.should == @session
    end
  end

  describe "#base_url" do
    before do
      @user = "user"
      @api_key = "key"
      @secret = "secret"
      @nitro = NitroApi::NitroApi.new @user, @api_key, @secret
    end

    it "has the correct default URL" do
      @nitro.base_url.should == 'https://sandbox.bunchball.net/nitro/json'
    end

    it "correctly uses the configured protocol value" do
      @nitro.protocol = 'http'
      @nitro.base_url.should == 'http://sandbox.bunchball.net/nitro/json'
    end

    it "correctly uses the configured host value" do
      @nitro.host = 'example.com'
      @nitro.base_url.should == 'https://example.com/nitro/json'
    end

    it "correctly uses the configured accepts value" do
      @nitro.accepts = 'xml'
      @nitro.base_url.should == 'https://sandbox.bunchball.net/nitro/xml'
    end
  end

  describe "#base_url_path" do
    it "correclty users the configured accepts value" do
      @nitro.base_url_path.should == '/nitro/json'

      @nitro.accepts = 'xml'
      @nitro.base_url_path.should == '/nitro/xml'
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

      it "sends one action with specified session key on query string" do
        action_name = "action"
        session = '2'
        params = {"tags" => action_name,
                  "sessionKey" => session,
                  "method" => "user.logAction"
        }
        opts = {session_key: session}
        url = @nitro.base_url + "?.*method=user.logAction.*"
        stub_http_request(:get, Regexp.new(url)).
            with(:query => params).
            to_return(:body => @success)

        @nitro.log_action action_name, opts
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

    describe "#get_points_balance options_hash" do
      it "gets the default points" do
        params = {"sessionKey" => @session,
                  "method" => "user.getPointsBalance"
        }
        url = @nitro.base_url + "?.*method=user.getPointsBalance.*"
        stub_http_request(:get, Regexp.new(url)).
            with(:query => params).
            to_return(:body => @success)

        @nitro.get_points_balance
      end

      it "passes through all the expected parameters" do
        options = {
            point_category: 'other_points',
            criteria: 'BALANCE',
            start: '1354636962',
            end: '1354637015',
            tags: 'beans,rice',
            user_id: 'another_user',
        }
        url = @nitro.base_url + '?criteria=BALANCE&end=1354637015&method=user.getPointsBalance&pointCategory=other_points&sessionKey=1&start=1354636962&tags=beans,rice&userId=another_user'
        stub_http_request(:get, url).
            to_return(:body => @success)

        @nitro.get_points_balance options
      end

      it "passes through only the expected parameters" do
        options = {
            point_category: 'other_points',
            criteria: 'BALANCE',
            start: '1354636962',
            end: '1354637015',
            tags: 'beans,rice',
            user_id: 'another_user',
            non_param: 'some_unknown_param'
        }
        url = @nitro.base_url + '?criteria=BALANCE&end=1354637015&method=user.getPointsBalance&pointCategory=other_points&sessionKey=1&start=1354636962&tags=beans,rice&userId=another_user'
        stub_http_request(:get, url).
            to_return(:body => @success)

        @nitro.get_points_balance options
      end
    end

    describe "#get_points_leaders options_hash" do
      it "gets points leaders" do
        options = {
          return_count: 20,
          duration: 'ALLTIME',
          point_category: 'points',
          criteria: 'CREDITS'
        }

        results = { 'Nitro' => {
          "res"=>"ok",
          "method"=>"site.getPointsLeaders",
          "leaders"=> {
            "Leader"=>[ {
              "UserPreferences"=>true,
              "userId"=>"user_id1",
              "points"=>"860"
            }, {
              "UserPreferences"=>true,
              "userId"=>"user_id2",
              "points"=>"620"
            } ]
          }
        }}

        # TODO: Figure out why when passing these params into the http request stub
        #       the mock doesn't work (it errors out).
        #params = {
        #    'method' => 'site.getPointsLeaders',
        #    'sessionKey' => @session,
        #    'returnCount' => 20,
        #    'duration' => 'ALLTIME',
        #    'pointCategory' => 'points',
        #    'criteria' => 'CREDITS'
        #}

        url = @nitro.base_url + "?.*method=site.getPointsLeaders.*"
        stub_http_request(:any, Regexp.new(url)).
            #with(:query => params).
            to_return(status: 200, body: results.to_json)

        s = @nitro.get_points_leaders options
        s['res'].should == results['Nitro']['res']
        s['method'].should == results['Nitro']['method']
        s['leaders']['Leader'][0]['userId'].should == results['Nitro']['leaders']['Leader'][0]['userId']
        s['leaders']['Leader'][0]['points'].should == results['Nitro']['leaders']['Leader'][0]['points']
        s['leaders']['Leader'][1]['userId'].should == results['Nitro']['leaders']['Leader'][1]['userId']
        s['leaders']['Leader'][1]['points'].should == results['Nitro']['leaders']['Leader'][1]['points']
      end
    end
  end


  context "batch jobs" do
    describe "#start_batch!" do
      it "starts a batch successfully" do
        @nitro.start_batch!
      end

      it "errors on second call to start_batch!" do
        @nitro.start_batch!
        expect {@nitro.start_batch!}.to raise_error(NitroApi::NitroError)
      end
    end

    describe "#cancel_batch" do
      it "cancels a batch successfully" do
        @nitro.start_batch!
        @nitro.cancel_batch
      end
    end

    describe "#run_batch" do
      describe "#login" do
        it "should set session id for a successful batch call" do
          mock_json = {'Nitro' => {'Login' => {'sessionKey' => @session}, 'method' => 'user.login', 'res' => 'ok'}}
          url = @nitro.base_url #+ "?.*method=batch.run.*"
          stub_http_request(:get, Regexp.new(url)).
              to_return(:body => mock_json.to_json)

          @nitro.start_batch!
          @nitro.login
          @nitro.run_batch

          @nitro.session.should == @session
        end
      end

      it "should call two methods successfully" do
        action_name = "action"
        mock_json = { 'Nitro' =>
            { 'res' => 'ok',
              'method' => 'batch.run',
              'Nitro' => [
                  {'Login' => {'sessionKey' => @session}, 'method' => 'user.login', 'res' => 'ok'},
                  {'res' => 'ok', 'method' => 'user.logAction'}
              ]
            }
        }
        url = @nitro.base_url #+ "?.*method=batch.run.*"
        stub_http_request(:post, Regexp.new(url)).
            to_return(:body => mock_json.to_json)

        @nitro.start_batch!
        @nitro.login
        @nitro.log_action action_name
        s = @nitro.run_batch

        @nitro.session.should == @session
        s['res'].should == mock_json['Nitro']['res']
        s['method'].should == mock_json['Nitro']['method']
        s['Nitro'][1]['res'].should == mock_json['Nitro']['Nitro'][1]['res']
        s['Nitro'][1]['method'].should == mock_json['Nitro']['Nitro'][1]['method']
      end

      it "should call the same method twice successfully" do
        action_name1 = "action1"
        action_name2 = "action2"
        mock_json = { 'Nitro' =>
                          { 'res' => 'ok',
                            'method' => 'batch.run',
                            'Nitro' => [
                                {'res' => 'ok', 'method' => 'user.logAction'},
                                {'res' => 'ok', 'method' => 'user.logAction'}
                            ]
                          }
        }
        url = @nitro.base_url #+ "?.*method=batch.run.*"
        stub_http_request(:post, Regexp.new(url)).
            to_return(:body => mock_json.to_json)

        @nitro.session = @session
        @nitro.start_batch!
        @nitro.log_action action_name1
        @nitro.log_action action_name2
        s = @nitro.run_batch

        s['res'].should == mock_json['Nitro']['res']
        s['method'].should == mock_json['Nitro']['method']
        s['Nitro'][1]['res'].should == mock_json['Nitro']['Nitro'][1]['res']
        s['Nitro'][1]['method'].should == mock_json['Nitro']['Nitro'][1]['method']
      end

      it "should call the same method twice but using different session keys successfully" do
        action_name1 = "action1"
        action_name2 = "action2"
        session_key1 = '111'
        session_key2 = '222'

        mock_json = { 'Nitro' =>
                          { 'res' => 'ok',
                            'method' => 'batch.run',
                            'Nitro' => [
                                {'res' => 'ok', 'method' => 'user.logAction'},
                                {'res' => 'ok', 'method' => 'user.logAction'}
                            ]
                          }
        }
        expected_post_body = "method=batch.run&methodFeed=%5B%22tags%3Daction1%26method%3Duser.logAction%26sessionKey%3D111%22%2C%22tags%3Daction2%26method%3Duser.logAction%26sessionKey%3D222%22%5D"

        url = @nitro.base_url #+ "?.*method=batch.run.*"
        stub_http_request(:post, Regexp.new(url)).
            with(body: expected_post_body).
            to_return(body: mock_json.to_json)

        @nitro.session = @session
        @nitro.start_batch!
        @nitro.log_action(action_name1, {session_key: session_key1})
        @nitro.log_action(action_name2, {session_key: session_key2})
        s = @nitro.run_batch

        s['res'].should == mock_json['Nitro']['res']
        s['method'].should == mock_json['Nitro']['method']
        s['Nitro'][1]['res'].should == mock_json['Nitro']['Nitro'][1]['res']
        s['Nitro'][1]['method'].should == mock_json['Nitro']['Nitro'][1]['method']
      end

      describe "#challenge_progress" do
        it "should not allow the call in batch mode" do
          @nitro.start_batch
          expect {@nitro.challenge_progress }.to raise_error(NitroApi::NitroError)
        end
      end

      describe "#action_history" do
        it "should not allow the call in batch mode" do
          @nitro.start_batch
          expect {@nitro.action_history 'action1'}.to raise_error(NitroApi::NitroError)
        end
      end
    end
  end

  context "https connections" do
    it "makes a single call successfully via https" do
      @nitro.protocol = 'https'
      mock_json = {"Nitro" => {"Login" => {"sessionKey" => @session}}}
      url = @nitro.base_url + "?.*method=user.login.*"
      stub_http_request(:get, Regexp.new(url)).
          to_return(:body => mock_json.to_json)

      @nitro.login
      @nitro.session.should == @session
    end

    it "makes a batch call successfully via https" do
      @nitro.protocol = 'https'
      mock_json = {'Nitro' => {'Login' => {'sessionKey' => @session}, 'method' => 'user.login', 'res' => 'ok'}}
      url = @nitro.base_url #+ "?.*method=batch.run.*"
      stub_http_request(:get, Regexp.new(url)).
          to_return(:body => mock_json.to_json)

      @nitro.start_batch!
      @nitro.login
      @nitro.run_batch

      @nitro.session.should == @session
    end
  end

end

