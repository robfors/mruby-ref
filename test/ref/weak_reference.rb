assert("Ref::WeakReference::new") do

  # build again for the same object
  o = Object.new
  r1 = Ref::WeakReference.new(o)
  r2 = Ref::WeakReference.new(o)
  assert_same(r1, r2)

  # build for different object
  r1 = Ref::WeakReference.new(Object.new)
  r2 = Ref::WeakReference.new(Object.new)
  assert_not_same(r1, r2)

end


assert("Ref::WeakReference#initialize") do

  # don't hold return value
  Ref::WeakReference.new(Object.new)
  # should not cause an issue when the gc is run
  GC.start

  # hold return value
  r = Ref::WeakReference.new(Object.new)
  # should not cause an issue when the gc is run
  GC.start

  # build for direct object
  r = Ref::WeakReference.new(Finalize::Emittable.new)
  assert_true(r.instance_of?(Ref::WeakReference))
  assert_equal(false, r.instance_variable_get(:@indirect))

  # build for indirect object
  r = Ref::WeakReference.new(Object.new)
  assert_true(r.instance_of?(Ref::WeakReference))
  assert_equal(true, r.instance_variable_get(:@indirect))

  # pass invalid object type
  assert_raise(TypeError) { Ref::WeakReference.new(2) }
  # then check that its finalizer won't cause any issues
  GC.start

end


assert("Ref::WeakReference#define_finalizer") do

  $count = 0
  f = Proc.new { $count += 1 }
  o = Object.new
  r = Ref::WeakReference.new(o)
  r.define_finalizer(f)
  o = nil
  GC.start
  Finalize.process
  assert_equal(1, $count)

  # dead object
  assert_raise(Ref::DeadObjectError) { r.define_finalizer(f) }

end


assert("Ref::WeakReference#indirect") do

  # build for direct object
  r = Ref::WeakReference.new(Finalize::Emittable.new)
  assert_equal(false, r.indirect)

  # build for indirect object
  r = Ref::WeakReference.new(Object.new)
  assert_equal(true, r.indirect)

end


assert("Ref::WeakReference#object") do

  # simulate interpreter shutting down
  o = Object.new
  r = Ref::WeakReference.new(o)
  # mock method
  original_method = Ref.method(:alive?).to_proc
  Ref.singleton_class.define_method(:alive?) { false }
  # run test
  assert_nil(r.object)
  # clean up
  Ref.singleton_class.define_method(:alive?, &original_method)

  o = (Class.new { def m; :v; end }).new
  r = Ref::WeakReference.new(o)
  # can not be collected yet
  GC.start
  GC.start
  assert_same(o, r.object)
  # check for correct object
  assert_equal(:v, r.object.m)

  # can be collected
  o = nil
  # because o was an indirect object, we expect GC.start to be called in #object
  assert_equal(nil, r.object)

  # try for direct object
  o = Finalize::Emittable.new
  r = Ref::WeakReference.new(o)
  # can not be collected yet
  GC.start
  GC.start
  assert_same(o, r.object)
  # can be collected
  o = nil
  o = r.object # capture the value as soon as possible to try to avoid the gc collecting it
  # probably will not be destroyed yet
  # if this assert fails that is ok, we should just remove the assert
  #   we are just observing the behaviour of mruby's GC
  assert_kind_of(Finalize::Emittable, o)
  o = nil
  GC.start
  # definitely destroyed now
  assert_equal(nil, r.object)

end


assert("Ref::WeakReference#undefine_finalizer") do

  $count = 0
  f1 = Proc.new { $count += 1 }
  f2 = Proc.new { $count += 1 }
  o = Object.new
  r = Ref::WeakReference.new(o)
  r.define_finalizer(f1)
  r.define_finalizer(f2)
  r.undefine_finalizer(f1)
  o = nil
  GC.start
  Finalize.process
  assert_equal(1, $count)

  # dead object
  assert_raise(Ref::DeadObjectError) { r.undefine_finalizer(f2) }

end


assert("Ref::WeakReference#update") do

  o = Object.new
  r = Ref::WeakReference.new(o)
  o = nil
  r.update # should run GC
  assert_nil(r.object)

end
