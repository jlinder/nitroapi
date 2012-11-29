module NitroApi
  module BatchCalls

    private

    # Actually perform the batch call.
    # @return [Hash] The hash containing the results from the nitro server
    def make_run_batch_call
      return false if @batch.nil? or @batch.size == 0

      # The nitro API returns a differently formatted result if called with
      # only one action. Thus, they need to be handled differently.
      if @batch.size == 1
        handle_batch_single_action
      else
        handle_batch_multiple_actions
      end
    end

    # This function handles making the call when there is only one call in
    # the batch.
    def handle_batch_single_action
      result = really_make_call(@batch[0][:params], @batch[0][:method])
      @batch = nil

      # TODO: improve the handling of other methods if only one is called with batch
      if result['method'] == 'user.login' and result['res'] == 'ok'
        @session = result['Login']['sessionKey']
      end
      result
    end

    # This function handles making the call when there is more than one call in
    # the batch.
    def handle_batch_multiple_actions
      # TODO: improve handling of errors in the batch response
      actions = []
      @batch.each do |action|
        actions << to_query(action[:params])
      end

      results = really_make_call({'method' => 'batch.run','methodFeed' => JSON.dump(actions)}, :post)
      @batch = nil
      extract_session_key results
      results
    end

    # Extracts the session key from the results when multiple method calls are
    # made in the batch.
    # @param [Hash] batch_results The hash containing the results from the
    #               batch call
    def extract_session_key batch_results
      batch_results['Nitro'].each do |result|
        if result['method'] == 'user.login' and result['res'] == 'ok'
          @session = result['Login']['sessionKey']
          break
        end
      end
    end

  end
end
