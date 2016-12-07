module Errors
  class HbxException < Exception
    attr_accessor :message, :code

    def initialize message:, code:
      @message = message
      @code = code
    end
  end
end