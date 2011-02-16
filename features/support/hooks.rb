require 'fileutils'

After do
  FileUtils.rm_rf @tmpdir if @tmpdir
end

