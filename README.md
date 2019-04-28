# mruby-ref
An _mruby_ gem that implements weak references. It is a partial port of [_Ref_](https://github.com/ruby-concurrency/ref), a similar gem built for less lightweight Ruby implementations. Internally, _mruby-ref_ relies on [_mruby-finalize_](https://github.com/robfors/mruby-finalize) to seamlessly work around the limitations of _mruby_ and listen for the destruction of referenced objects.

## Available Tools

The following tools have been ported from _Ref_. If you would like to have more of the tools ported feel free to submit an issue or pull request.

### WeakReference

A reference to an object which can be collected at any time:
```ruby
o = Object.new
r = Ref::WeakReference.new(o)
# can not be collected yet
GC.start
r.object #=> o
o = nil
# can be collected
GC.start
r.object #=> nil
```

#### Shutdown

Keep in mind that all `WeakReference`s are disabled when the interpreter is shutdown, specifically when the _mruby-ref_ gem finalizer (`mrb_mruby_ref_gem_final`) is called. Any gem that lists _mruby-ref_ as a dependency can use its own finalizer to clean up any code holding a `WeakReference`, to avoid unexpected behaviour. This will be safe as _mruby_ calls gem finalizers in a hierarchical order (dependee's finalizer before the dependent's finalizer).

#### Performance

When `#object` is called to retrieve most types of objects, the GC will be forced to run to ensure a dead object is not returned. Frequent calls to `WeakReference`s or the other tools will cause the GC to be run often, which may result in a significant performance hit. However, `WeakReference`s built for `Ref::Emittable`s will never need to run the GC and are anticipated to be used for this purpose. Review the documentation for _mruby-finalize_ and _mruby-ref_ to lean how this works.

### WeakValueMap

A map where the values can be collected at any time:
```ruby
m = Ref::WeakValueMap.new
o1 = Object.new
o2 = Object.new
m[:k] = o1
m[1] = o2
GC.start
m[:k] #=> o1
m[1] #=> o2
o1 = nil
GC.start
m[:k] #=> nil
m[1] #=> o2
o2 = nil
GC.start
m[:k] #=> nil
m[1] #=> nil
```
