module Rex
  class Input
    def self.[](*filenames)
      new(filenames)
    end

    attr_reader :filenames

    def initialize(filenames)
      @filenames = filenames
    end

    # iterates over the files in filenames one by one, line by line
    def each

    end

    # returns name of the current file
    def filename

    end

    # returns the current file as an I/O object
    def file

    end
  end
end
