module Rex
  class Line
    attr_accessor :text
    attr_accessor :position

    def initialize(text)
      @text = text
      @position = 0
    end

    def cursor
      @text[@position]
    end

    def consume
      @position += 1
    end
  end
end
