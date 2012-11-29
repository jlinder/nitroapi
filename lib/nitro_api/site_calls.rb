module NitroApi
  module SiteCalls
    def make_points_leaders_call opts
      params = {
          :method => 'site.getPointsLeaders'
      }

      # Only include the session key when it is present. This is to make batch
      # calls work for this method.
      params[:sessionKey] = @session if @session

      opts_list = {
          'criteria' => 'criteria',
          'point_category' => 'pointCategory',
          'return_count' => 'returnCount',
          'start' => 'start',
          'duration' => 'duration',
          'user_ids' => 'userIds',
          'tags' => 'tags',
          'tags_operator' => 'tagsOperator',
          'group_name' => 'groupName',
          'with_rank' => 'withRank',
          'with_surrounding_users' => 'withSurroundingUsers',
          'preferences' => 'preferences'
      }

      opts.each do |key,value|
        params[opts_list[key]] = value if opts_list.has_key?(key)
      end
      make_call(params, :get)
    end
  end
end
