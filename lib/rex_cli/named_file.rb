module Rex
  class NamedFile
    attr_reader :file
    attr_reader :name

    def initialize(path)
      @file = File.open(path, 'r')
      @name = path
    end
  end
end
