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
      @session = response["Login"]["sessionKey"]
    end

    def make_log_action_call actions, opts={}
      value = opts.delete(:value)
      user_id = opts.delete(:other_user)
      params = {
          :tags => actions.is_a?(Array) ? actions.join(",") : actions,
          :sessionKey => @session,
          :method => 'user.logAction'
      }
      params[:value] = value.to_s if value && !value.to_s.empty?
      params[:userId] = user_id if user_id && !user_id.to_s.empty
      make_call(params)
    end

    def make_challenge_progress_call opts={}
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
  end
end
