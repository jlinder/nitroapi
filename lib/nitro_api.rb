require 'json'
require 'digest/md5'
require 'net/http'

module NitroApi
  HOST = "http://sandbox.bunchball.net/nitro/"
  ACCEPT = "json?"

  class NitroError < StandardError
    attr_accessor :code

    def initialize (err_code=nil)
      @code = err_code
    end
  end

  class NitroApi
    # Constants
    CRITERIA_MAX = "MAX";
    CRITERIA_CREDITS = "credits";
    POINT_CATEGORY_ALL = "all";
    TAGS_OPERATOR_OR = "OR";   
    
    def initialize (user_id, api_key, secret)
      # Required Parameters
      @secret = secret
      @api_key = api_key
      @user = user_id
    end
    
    #  Method for constructing a signature
    def sign
      time = Time.now.gmtime.to_i.to_s
      unencrypted_signature = @api_key + @secret + time + @user.to_s
      return Digest::MD5.hexdigest(unencrypted_signature + unencrypted_signature.length.to_s)
    end
	
    def login
      params = {
        :sig => sign,
        :ts => Time.now.gmtime.to_i.to_s,
        :apiKey => @api_key,
        :userId => @user,
        :method => 'user.login'
      }
      request = HOST + ACCEPT + to_query(params)
      data = Net::HTTP.get_response(URI.parse(request)).body
      json = JSON.parse(data)
      response = json["Nitro"]
      error = response["Error"]
      if error
        raise NitroError.new(error["Code"]), error["Message"]
      else
        @session =  response["Login"]["sessionKey"]
      end
    end
    
    def log_action(actions, value=nil)
      params = {
        :tags => actions.is_a?(Array) ? actions.join(",") : actions,
        :sessionKey => @session,
        :userId => @user,
        :method => 'user.logAction'
      }
      params['value'] = value.to_s if value && !value.to_s.empty?
      request = HOST + ACCEPT + to_query(params)
      p request
      data = Net::HTTP.get_response(URI.parse(request)).body
      json = JSON.parse(data)
      response = json["Nitro"]
      error = response["Error"]
      if error
        raise NitroError.new(error["Code"]), error["Message"]
      end     
    end

    private

    def to_query params
      params.map {|k,v| "#{k.to_s}=#{v.to_s}"}.join("&")
    end
  end
end
