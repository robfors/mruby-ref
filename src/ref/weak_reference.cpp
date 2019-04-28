#include "weak_reference.hpp"


using namespace std;


namespace Ref
{
  namespace WeakReference
  {

    
    struct mrb_data_type _data_type = {"Ref::WeakReference", mrb_free};


    void _clear_object(mrb_state* mrb, mrb_value self)
    {
      mrb_value* object_ptr = (mrb_value*)mrb_data_get_ptr(mrb, self, &_data_type);
      *object_ptr = mrb_nil_value();
    }


    mrb_value _get_object(mrb_state* mrb, mrb_value self)
    {
      mrb_value* object_ptr = (mrb_value*)mrb_data_get_ptr(mrb, self, &_data_type);
      // check if the referenced object is dead as as a precaution
      if (mrb_object_dead_p(mrb, (struct RBasic*)mrb_obj_ptr(*object_ptr)))
        *object_ptr = mrb_nil_value();
      return *object_ptr;
    }


    mrb_value _set_object(mrb_state* mrb, mrb_value self)
    {
      mrb_value object;
      mrb_get_args(mrb, "o", &object);

      auto finalizer = [mrb, self] {
        _clear_object(mrb, self);
        // prevent memory leak
        mrb_gc_unregister(mrb, self);
      };
      // call this before initializing the data pointer as it may raise an error if object is not definable
      Finalize::DefinitionAffiliation affiliation = Finalize::define_finalizer(mrb, object, finalizer);
      // this WeakReference object must exist when the finalizer is executed
      //   be sure to undo this later to prevent a memory leak
      mrb_gc_register(mrb, self);

      // clear any existing data
      mrb_value* object_ptr = (mrb_value*)DATA_PTR(self);
      if (object_ptr != nullptr)
        mrb_free(mrb, object_ptr);

      object_ptr = (mrb_value*)mrb_malloc(mrb, sizeof(mrb_value));
      *object_ptr = object;
      mrb_data_init(self, object_ptr, &_data_type);

      return mrb_bool_value(affiliation == Finalize::DefinitionAffiliation::indirect);
    }


    void setup(mrb_state* mrb)
    {
      RClass* klass = mrb_define_class_under(mrb, mrb_class_ptr(Ref::module(mrb)), "WeakReference", mrb->object_class);
      MRB_SET_INSTANCE_TT(klass, MRB_TT_DATA);

      mrb_define_method(mrb, klass, "get_object", _get_object, MRB_ARGS_NONE());
      mrb_define_method(mrb, klass, "set_object", _set_object, MRB_ARGS_REQ(1));
    }


  }
}
