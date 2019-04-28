module Ref

  # Raised when trying to access a destroyed object.
  class DeadObjectError < RuntimeError

    def initialize(message = 'object has been destroyed')
      super
    end

  end

end
