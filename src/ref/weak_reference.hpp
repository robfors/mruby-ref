#ifndef _REF_WEAK_REFERENCE_HPP_
#define _REF_WEAK_REFERENCE_HPP_


#include "../ref.hpp"


namespace Ref
{

  // Used to hold a reference to an object that can still be garbage collected.
  //
  // A data class is needed to hold the reference to the object without the GC knowing.
  //
  // See weak_reference.rb for information on the finalizer that is used to keep track of the
  // referenced object.
  namespace WeakReference
  {

    // public

    // define the class and its C methods
    void setup(mrb_state* mrb);

    // private
    
    // receive the data pointer and clear the referenced object
    void _clear_object(mrb_state* mrb, mrb_value self);
    
    // receive the data pointer and return the referenced object
    mrb_value _get_object(mrb_state* mrb, mrb_value self);

    // initialize the data pointer and set the referenced object
    mrb_value _set_object(mrb_state* mrb, mrb_value self);

  }
}


#endif
