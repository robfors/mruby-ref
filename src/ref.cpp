#include "ref.hpp"


using namespace std;


namespace Ref
{


  // multiple states may exist at the same time so a container is used to keep track of them all
  unordered_set<mrb_state*> _alive_mrb_states;


  void finalize(mrb_state* mrb)
  {
    _alive_mrb_states.erase(mrb);
  }


  void initialize(mrb_state* mrb)
  {
    _setup(mrb);
    _alive_mrb_states.insert(mrb);
  }


  mrb_value _is_alive(mrb_state* mrb, mrb_value self)
  {
    return mrb_bool_value(_alive_mrb_states.count(mrb) != 0);
  }


  mrb_value module(mrb_state* mrb)
  {
    return mrb_obj_value(mrb_module_get(mrb, "Ref"));
  }


  void _setup(mrb_state* mrb)
  {
    RClass* module = mrb_define_module(mrb, "Ref");
    mrb_define_class_method(mrb, module, "alive?", _is_alive, MRB_ARGS_NONE());

    WeakReference::setup(mrb);
  }


}


void mrb_mruby_ref_gem_final(mrb_state* mrb)
{
  Ref::finalize(mrb);
}


void mrb_mruby_ref_gem_init(mrb_state* mrb)
{
  Ref::initialize(mrb);
}
