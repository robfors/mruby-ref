module Ref

  # Holds a reference to an object that can still be garbage collected.
  #
  # This implementation uses mruby-finalize, that gem's documentation should be reviewed for a
  # better understanding of this implementation. A finalizer is used to keep track of when the
  # referenced object is destroyed and update the {WeakReference}. The C++ API must be used, as
  # defined finalizers are executed immediately after the object is destroyed. If the Ruby API were
  # used we would not be able to call {WeakReference}s inside a Ruby API finalizer as the state of
  # a {WeakReference} could be stale. Further, we keep track of the type of finalizer we are
  # defining on the object. If the finalizer is indirect, we must also consider the {WeakReference}
  # as indirect. For such a {WeakReference}, we are forced to run the GC every time we retrieve its
  # object to ensure the state of the {WeakReference} is not stale. For performance reasons you may
  # want to design your code such that {WeakReference}s are build for +Finalize::Emittable+s.
  # This way the finalizers that are defined will be direct and the GC will never need to be run.
  #
  # {WeakReference}s are disabled as soon as the interpreter is shutdown, specifically when the
  # mruby-ref gem's finalizer (+mrb_mruby_ref_gem_final+) is called. This is because finalizers
  # will be disabled and we won't be able to tell when the referenced objects get destroyed. For
  # safety we must assume all the referenced objects have been destroyed.
  #
  # For convenience some shortcut methods are included to let you define and undefine finalizers.
  class WeakReference

    # Build a {WeakReference} for an object.
    # There is no benefit to creating multiple {WeakReference}s for the same object so we will
    # reuse existing {WeakReference}s.
    # @param object [Object]
    # @raise TypeError if a {WeakReference} can not be build for the object
    # @return [WeakReference]
    def self.new(object)
      # we don't expect +nil+ to work anyway, but we will include this to be safe
      raise TypeError if object == nil
      weak_reference = Attribute.get(object, :_ref__weak_reference)
      unless weak_reference
        weak_reference = super(object)
        # point the object to the Ref::WeakReference
        Attribute.set(object, :_ref__weak_reference, weak_reference)
      end
      weak_reference
    end

    # Create a new {WeakReference} for an object.
    # @param object [Object]
    # @raise TypeError if a {WeakReference} can not be build for the object
    # @return [WeakReference]
    def initialize(object)
      begin
        @indirect = set_object(object)
      rescue TypeError
        raise TypeError, "can not build Ref::WeakReference for #{object.class}"
      end
    end

    # Define a finalizer on the referenced object.
    # Just a shortcut for retrieving the object and calling +Finalize::define_finalizer+ on it.
    # @param finalizer [Proc]
    # @raise DeadObjectError if the object is already destroyed
    # @raise TypeError if +finalizer+ is not a Proc
    # @raise ArgumentError if the +finalizer+ is already defined on the object
    # @return [void]
    # @see Finalizer::define_finalizer
    def define_finalizer(finalizer)
      object = self.object
      raise DeadObjectError, 'can not define finalizer, object was destroyed' if object == nil
      Finalize.define_finalizer(object, finalizer)
      nil
    end

    # @!method get_object
    #   Try to retrieve the referenced object from the data pointer.
    #   @api private
    #   @return [nil,Object] the referenced object or +nil+ if it was destroyed

    # Returns if {WeakReference} is indirect.
    # A {WeakReference} is indirect if its referenced object's defined finalizer is indirect.
    # An indirect {WeakReference} will require the GC to be run to guarantee it is not stale.
    # @return [Boolean] 
    attr_reader :indirect

    # Try to get the referenced object.
    # @return [nil,Object] the referenced object or +nil+ if it was destroyed
    def object
      unless Ref.alive?
        # this indicates that finalizers are no longer being executed
        # for safety we must assume the referenced object has been destroyed
        return nil
      end
      update
      get_object
    end

    # @!method set_object(object)
    #   Initialize the data pointer and set the referenced object.
    #   @api private
    #   @return [void]

    # Undefine a finalizer on the referenced object.
    # Just a shortcut for retrieving the object and calling +Finalize::undefine_finalizer+ on it.
    # @param finalizer [Proc]
    # @raise DeadObjectError if the object is already destroyed
    # @raise TypeError if +finalizer+ is not a Proc
    # @raise ArgumentError if the +finalizer+ is not defined on the object
    # @return [void]
    # @see Finalizer::undefine_finalizer
    def undefine_finalizer(finalizer)
      object = self.object
      raise DeadObjectError, 'can not undefine finalizer, object was destroyed' if object == nil
      Finalize.undefine_finalizer(object, finalizer)
      nil
    end

    # Update the state of the {WeakReference}.
    # @api private
    # @return [void]
    def update
      GC.start if @indirect
    end

  end

end
