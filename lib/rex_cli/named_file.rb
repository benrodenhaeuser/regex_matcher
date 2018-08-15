module Rex
  class NamedFile
    attr_reader :file
    attr_reader :name

    def initialize(path = nil)
      if path
        @file = File.open(path, 'r')
        @name = path
      else
        @file = $stdin
        @name = '-'
      end
    end
  end
end
