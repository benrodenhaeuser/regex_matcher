module Rex
  class Line
    attr_accessor :text
    attr_accessor :position
    attr_accessor :line_number

    def initialize(text)
      @text = text
      @position = 0
    end

    def [](index)
      @text[index]
    end

    def to_s
      @text
    end

    def length
      @text.length
    end

    def cursor
      @text[@position]
    end

    def consume
      @position += 1
    end
  end
end
