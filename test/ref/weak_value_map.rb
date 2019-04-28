assert("Ref::WeakValueMap::new") do

  m = Ref::WeakValueMap.new
  assert_true(m.instance_of?(Ref::WeakValueMap))

end


assert("Ref::WeakValueMap#[]") do

  # can not be collected yet
  m = Ref::WeakValueMap.new
  o = Object.new
  r = Ref::WeakReference.new(o)
  m.instance_variable_set(:@map, {:k => r})
  GC.start
  GC.start
  assert_same(o, m[:k])

  # can be collected
  m = Ref::WeakValueMap.new
  o = Object.new
  r = Ref::WeakReference.new(o)
  m.instance_variable_set(:@map, {:k => r})
  o = nil
  assert_equal(nil, m[:k])

  # try a map with multiple values
  m = Ref::WeakValueMap.new
  o1 = Object.new
  o2 = Object.new
  r1 = Ref::WeakReference.new(o1)
  r2 = Ref::WeakReference.new(o2)
  m.instance_variable_set(:@map, {:k => r1, 1 => r2})
  GC.start
  assert_same(o1, m[:k])
  assert_same(o2, m[1])
  o1 = nil
  assert_equal(nil, m[:k])
  assert_same(o2, m[1])
  o2 = nil
  assert_equal(nil, m[:k])
  assert_equal(nil, m[1])

end


assert("Ref::WeakValueMap#[]=") do

  m = Ref::WeakValueMap.new
  o = Object.new
  m[:k] = o
  GC.start
  assert_same(o, m[:k])
  o = nil
  assert_equal(nil, m[:k])

  # try a map with multiple values
  m = Ref::WeakValueMap.new
  o1 = Object.new
  o2 = Object.new
  m[:k] = o1
  m[1] = o2
  GC.start
  assert_same(o1, m[:k])
  assert_same(o2, m[1])
  o1 = nil
  assert_equal(nil, m[:k])
  assert_same(o2, m[1])
  o2 = nil
  assert_equal(nil, m[:k])
  assert_equal(nil, m[1])

  # replace an alive object
  m = Ref::WeakValueMap.new
  o1 = Object.new
  o2 = Object.new
  m[:k] = o1
  GC.start
  assert_same(o1, m[:k])
  m[:k] = o2
  assert_same(o2, m[:k])
  o1 = nil
  GC.start
  assert_same(o2, m[:k]) # check that the clean up finalizer did not remove the new value
  o2 = nil
  assert_same(o2, m[:k])

end


assert("Ref::WeakValueMap#update") do

  # check for memory leak
  # check that finalizers are working
  m = Ref::WeakValueMap.new
  o1 = Object.new
  o2 = Object.new
  m[:k] = o1
  m[1] = o2
  GC.start
  assert_equal(2, m.instance_variable_get(:@map).length)
  o1 = nil
  o2 = nil
  GC.start
  m.update
  assert_equal(0, m.instance_variable_get(:@map).length)

end
