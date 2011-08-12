module NitroApi
  class Challenge
    attr_accessor :name, :description, :completed, :full_url, :thumb_url
    attr_accessor :rules

    def initialize()
      @rules = []
    end
  end
end
