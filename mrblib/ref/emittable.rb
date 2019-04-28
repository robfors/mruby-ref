module Ref

  # An {Emittable} can immediately update a listening {WeakReference} after being destroyed by the GC.
  #
  # A {WeakReference} pointing to an {Emittable} will never need to run the GC. This may be
  # significantly beneficial for performance when referenced objects are retrieved often.
  #
  # +Finalize::Emittable+s can be used equivalently as this is just a subclass.
  class Emittable < Finalize::Emittable

  end

end
