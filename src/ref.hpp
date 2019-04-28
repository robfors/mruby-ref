#ifndef _REF_HPP_
#define _REF_HPP_


#include <new>
#include <functional>
#include <unordered_set>
#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/gc.h>

#include <finalize.hpp>


namespace Ref
{

  // public

  // finalizer for the gem
  // we use it to disable {WeakReference}s so we can avoid retrieving dead objects
  void finalize(mrb_state* mrb);

  // initializer for the gem
  // we use it to:
  //   - define the data classes and C methods
  //   - enable {WeakReference}s
  void initialize(mrb_state* mrb);

  // check if the interpreter is alive
  mrb_value is_alive(mrb_state* mrb, mrb_value self);

  // shortcut function to get the 'Ref' module
  mrb_value module(mrb_state* mrb);

  // private

  // define the data classes and C methods
  void _setup(mrb_state* mrb);

}


// called by mruby when it is shutting down
extern "C"
void mrb_mruby_ref_gem_final(mrb_state* mrb);

// called by mruby to setup the gem
extern "C"
void mrb_mruby_ref_gem_init(mrb_state* mrb);


#include "ref/weak_reference.hpp"

#endif
