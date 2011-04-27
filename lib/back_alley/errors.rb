module BackAlley
  class Error < Exception
    attr_accessor :code

    def initialize message ="", code
      self.code = code
      super message
    end
  end
  
  class ServerError < Error
    def initialize message ="", code=500
      super
    end
  end

  class ClientError < Error
    def initialize message ="", code=400
      super
    end
  end
end