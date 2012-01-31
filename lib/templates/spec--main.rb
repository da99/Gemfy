
require File.expand_path('spec/helper')
require '{{name}}'
require 'Bacon_Colored'

unless ARGV.detect { |a| File.exists?(a) }
  Dir.glob('spec/tests/*.rb').each { |file|
    require File.expand_path(file.sub('.rb', '')) if File.file?(file)
  }
end
