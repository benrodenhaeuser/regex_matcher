module Rex
  class Token
    attr_reader :type
    attr_reader :text

    def initialize(type, text)
      @type = type
      @text = text
    end
  end
end
