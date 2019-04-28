MRuby::Gem::Specification.new('mruby-ref') do |spec|
  spec.license = 'MIT'
  spec.author  = 'Rob Fors'
  spec.version = '0.0.0'
  spec.summary = 'reference objects that can be garbage collected'

  spec.rbfiles = Dir.glob("#{dir}/mrblib/**/*.rb")
  spec.cxx.flags << "-std=c++11"
  spec.objs = Dir.glob("#{dir}/src/**/*.cpp")
    .map { |f| objfile(f.relative_path_from(dir).pathmap("#{build_dir}/%X")) }

  spec.add_dependency('mruby-attribute', '~> 0', :github => 'robfors/mruby-attribute')
  spec.add_dependency('mruby-finalize', '~> 0', :github => 'robfors/mruby-finalize')

  spec.test_rbfiles = Dir.glob("#{dir}/test/**/*.rb")

  spec.add_test_dependency('mruby-metaprog', core: 'mruby-metaprog')
  spec.add_test_dependency('mruby-method', core: 'mruby-method')
end
