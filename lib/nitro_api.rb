require 'json'
require 'digest/md5'
require 'net/http'
require 'nitro_api/challenge'
require 'nitro_api/rule'
require 'nitro_api/batch_calls'
require 'nitro_api/user_calls'
require 'nitro_api/site_calls'

module NitroApi

  class NitroError < StandardError
    attr_accessor :code

    def initialize (err_code=nil)
      @code = err_code
    end
  end

  class NitroApi

    include BatchCalls
    include SiteCalls
    include UserCalls

    attr_accessor :protocol, :host, :accepts, :session

    # Initialize an instance
    # user_id - The id for the user in the nitro system
    # api_key - The API key for your Bunchball account
    # secret - The secret for your Bunchball account
    def initialize (user_id, api_key, secret)
      @secret = secret
      @api_key = api_key
      @user = user_id
      @batch = nil

      self.protocol = 'https'
      self.host = 'sandbox.bunchball.net'
      self.accepts = 'json'
    end

    # Start a batch call to the nitro API. Uses the "batch.run" method defined
    # here: https://bunchballnet-main.pbworks.com/w/page/53132313/batch_run
    # returns - false if a batch is already being composed, true otherwise
    def start_batch
      if @batch.nil?
        @batch = []
        return true
      end

      return false
    end

    # Start a batch call to the nitro API. Uses the "batch.run" method defined
    # here: https://bunchballnet-main.pbworks.com/w/page/53132313/batch_run
    # If a batch is already being composed, an error will be raised.
    def start_batch!
      if not start_batch
        raise NitroError.new, "A batch is already being composed."
      end
    end

    # Run the batch job. Requires that the 'start_batch' method has been called first.
    def run_batch
      make_run_batch_call
    end

    # Cancel the batch job. It clears out the any accumulated calls that have
    # been made since first calling start_batch
    def cancel_batch
      @batch = nil
    end

    #  Method for constructing a signature
    def sign(time)
      unencrypted_signature = @api_key + @secret + time + @user.to_s
      to_digest = unencrypted_signature + unencrypted_signature.length.to_s
      return Digest::MD5.hexdigest(to_digest)
    end

    # Login the user to the nitro system
    def login
      make_login_call
    end

    # Log actions to the nitro system
    # @param [String, Array[String]] actions The (list of) action tag(s) to log
    # @param [Hash] opts The options. They are:
    #                    :value - the value to send
    #                    :other_user - the ID of the user to which the action should be applied
    #                    :session_key - the session key to use for this call
    def log_action actions, opts={}
      make_log_action_call actions, opts
    end

    def challenge_progress opts={}
      make_challenge_progress_call opts
    end

    def award_challenge challenge
      make_award_challenge_call challenge
    end

    def action_history actions=[]
      make_action_history_call actions
    end

    def join_group group
      make_join_group_call group
    end

    # Get the points for a user.
    # @param [Hash] opts The list of options. The keys in the list are the
    #        snake_case versions names of the parameters to the getPointsBalance
    #        API call as defined here:
    #        https://bunchballnet-main.pbworks.com/w/page/53132548/user_getPointsBalance
    def get_points_balance opts={}
      make_get_points_balance_call opts
    end

    # Get the list of point leaders for the specified options.
    # opts - The list of options. The keys in the list are the snake_case
    #        versions names of the parameters to the getPointsLeaders API call
    #        as defined here:
    #        https://bunchballnet-main.pbworks.com/w/page/53132408/site_getPointsLeaders
    def get_points_leaders opts
      make_points_leaders_call opts
    end

    def base_url
      "#{self.protocol}://#{self.host}/nitro/#{self.accepts}"
    end

    private

    def valid_response? obj
      obj.is_a?(Array) || obj.is_a?(Hash)
    end

    def ensure_array items
      items.is_a?(Array) ? items : [items]
    end

    def make_call params, method=:get
      if @batch.nil?
        return really_make_call params, method
      else
        @batch << { params: params, method: method }
        nil
      end
    end

    def really_make_call params, method
      if :get == method
        request = "#{base_url}?#{to_query(params)}"
        data = Net::HTTP.get(URI.parse(request))
      elsif :post == method
        data = Net::HTTP.post_form(URI.parse(base_url), params)
        data = data.body
      end

      json = JSON.parse(data)
      response = json["Nitro"]
      error = response["Error"]
      if error
        raise NitroError.new(error["Code"]), error["Message"]
      else
        response
      end
    end

    def to_query params
      URI.escape(params.map { |k,v| "#{k.to_s}=#{v.to_s}" }.join("&"))
    end

    def symbolize_keys h
      result = {}
      h.keys.each do |key|
        result[(key.to_sym rescue key) || key] = h[key]
      end
      result
    end
  end
end
