def run_specs
  system("rake spec")
end

def run_features
  system("rake features")
end

watch('spec/.*\.rb$') {|md| run_specs}
watch('features/.*\.(feature|rb)$') {|md| run_features}
watch('(bin/jitsu|lib/.*\.(rb|yaml)$)') {|md| run_specs && run_features}

