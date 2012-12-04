module NitroApi
  module UserCalls

    def make_login_call
      ts = Time.now.utc.to_i.to_s
      params = {
          :sig => sign(ts),
          :ts => ts,
          :apiKey => @api_key,
          :userId => @user,
          :method => 'user.login'
      }
      response = make_call(params)
      if response.is_a?(Hash)
        @session = response["Login"]["sessionKey"]
      end
      response
    end

    def make_log_action_call actions, opts={}
      value = opts.delete(:value)
      user_id = opts.delete(:other_user)
      session_key = opts.delete(:session_key)
      params = {
          :tags => actions.is_a?(Array) ? actions.join(",") : actions,
          :method => 'user.logAction'
      }

      # Only include the session key when it is present. This is to make batch
      # calls work for this method.
      if session_key or @session
        params[:sessionKey] = session_key ? session_key : (@session ? @session : nil)
      end

      params[:value] = value.to_s if value && !value.to_s.empty?
      params[:userId] = user_id if user_id && !user_id.to_s.empty
      make_call(params)
    end

    def make_challenge_progress_call opts={}
      # TODO: add support for the user.getChallengeProgress call to nitroapi
      if not @batch.nil?
        raise NitroError.new(10000), "user.getChallengeProgress not supported in batch mode by nitroapi"
      end

      params = {
          :sessionKey => @session,
          :method => 'user.getChallengeProgress'
      }
      challenge = opts[:challenge]
      params['challengeName'] = challenge if challenge and !challenge.to_s.empty?
      params['showOnlyTrophies'] = opts.delete(:trophies_only) || false
      params['folder'] = opts.delete(:folder) if opts.has_key?(:folder)

      response = make_call(params)

      if valid_response?(response['challenges'])
        items = ensure_array(response['challenges']['Challenge'])
        items.reduce([]) do |challenges, item|
          challenge = Challenge.new
          challenge.name = item["name"]
          challenge.description = item["description"]
          challenge.full_url = item["fullUrl"]
          challenge.thumb_url = item["thumbUrl"]
          challenge.completed = item["completionCount"].to_i

          if valid_response?(item["rules"])
            ensure_array(item["rules"]['Rule']).each do |rule_elm|
              rule = Rule.new
              rule.action = rule_elm['actionTag']
              rule.type = rule_elm['type'].to_sym
              rule.completed = rule_elm['type'] == 'true'
              if rule_elm['goal'] && !rule_elm['goal'].empty?
                rule.goal = rule_elm['goal'].to_i
              end
              challenge.rules<< rule
            end
          end
          challenges<< challenge
        end
      end
    end

    def make_award_challenge_call(challenge)
      params = {
          :sessionKey => @session,
          :userId => @user,
          :method => 'user.awardChallenge',
          :challenge => challenge
      }
      make_call(params)
    end

    def make_action_history_call actions=[]
      # TODO: add support for the user.getActionHistory call to nitroapi
      if not @batch.nil?
        raise NitroError.new(10000), "user.getActionHistory not supported in batch mode by nitroapi"
      end

      params = {
          :sessionKey => @session,
          :method => 'user.getActionHistory'
      }
      if actions && !actions.empty?
        params[:tags] = actions.is_a?(Array) ? actions.join(",") : actions
      end
      response = make_call(params)
      if valid_response?(response['ActionHistoryRecord'])
        items = ensure_array(response['ActionHistoryRecord']['ActionHistoryItem'])
        items.reduce([]) do
        |history, item|
          history<< {:tags => item['tags'],
                     :ts => Time.at(item['ts'].to_i),
                     :value => item['value'].to_i
          }
        end
      else
        []
      end
    end

    def make_join_group_call group
      params = {
          :sessionKey => @session,
          :method => 'user.joinGroup',
          :groupName => group
      }
      make_call(params)
    end

    def make_get_points_balance_call opts={}
      params = {
          :method => 'user.getPointsBalance'
      }

      # Only include the session key when it is present. This is to make batch
      # calls work for this method.
      params[:sessionKey] = @session if @session

      opts_list = {
          'criteria' => 'criteria',
          'point_category' => 'pointCategory',
          'start' => 'start',
          'end' => 'end',
          'user_id' => 'userId',
          'tags' => 'tags',
      }

      opts.each do |key,value|
        params[opts_list[key]] = value if opts_list.has_key?(key)
      end
      make_call(params, :get)
    end
  end
end
