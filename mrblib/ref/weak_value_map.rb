module Ref

  # A map with values can be garbage collected.
  #
  # This implementation uses {WeakReference}s to keep track of destroyed values. It only relies on
  # finalizers to clean up expired {WeakReference}s to prevent a long term memory leak. The
  # mruby-finalize Ruby API can be used for this task.
  class WeakValueMap

    # Create a new {WeakValueMap}.
    # @return [WeakValueMap]
    def initialize
      @map = {}
    end

    # Get a value.
    # @param key [Object]
    # @return [nil,Object] the value or +nil+ if non existent or destroyed
    def [](key)
      Finalize.process # clean up any expired {WeakReference}s
      @map[key]&.object
    end

    # Set a value.
    # @param key [Object]
    # @param value [Object]
    # @raise TypeError if value can not be set
    # @return [Object] the value
    def []=(key, value)
      Finalize.process # clean up any expired {WeakReference}s
      begin
        new_reference = WeakReference.new(value)
      rescue TypeError
        raise TypeError, "a #{object.class} can not be used as a Ref::WeakValueMap value"
      end
      # we don't want the finalizer to inadvertently hold a reference to the value
      finalizer = cleanup_finalizer(key, new_reference)
      new_reference.define_finalizer(finalizer)
      @map[key] = new_reference
      value
    end

    # Built a finalizer for cleaning up a stale {WeakReference}.
    # @api private
    # @param key [Object]
    # @param reference [WeakReference]
    # @return [Proc]
    def cleanup_finalizer(key, reference)
      # be sure to check if the reference has already been replaced
      Proc.new { @map.delete(key) if @map[key] == reference }
    end

    # Remove expired {WeakReference}s.
    # Can be called on occasion to clean up the expired {WeakReference}s. It is just a shortcut to
    # +Finalize.process+. As long as you are occasionally calling {#get}, {#set} or
    # +Finalize.process+, than calling this is unnecessary.
    # @return [void]
    def update
      Finalize.process
    end

  end

end
