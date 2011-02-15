def run_specs
  system("rake spec")
end

def run_features
  system("rake features")
end

watch('(lib|bin|spec|features)/(.*\.rb|[^.])') do |md|
  run_specs && run_features
end

