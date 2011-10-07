
require File.expand_path('spec/helper')
require 'Gemfy'
class Box
  
  GEM_NAME = File.expand_path('.').split('/').reverse.detect { |f| !f.strip.empty? }
  TEMP     = "/tmp/#{GEM_NAME}/rand_#{rand(1000)}"
  BIN      = File.expand_path('.') + '/bin'
  BINARY   = File.join(BIN, GEM_NAME.upcase)

  attr_reader :dir
  
  def initialize name = :default
    if name === :default
      @dir = TEMP
    else
      @dir = File.join(TEMP, name)
    end
    
  end

  def shell raw_cmd
    cmd = raw_cmd.strip
    raise "Invalid characters: #{cmd}" if cmd[/\r|\n/]
    full = "cd #{dir} && #{cmd} 2>&1"
    val = `#{full}`.to_s.strip
    if $?.exitstatus != 0
      raise "Failed: #{full} -- Results:\n#{val}"
    end
    
    val
  end
  
  def bin raw_cmd
    shell "#{BINARY} #{raw_cmd}"
  end
  
  def down name
    Box.new(name)
  end
  
  def read file
    File.read(File.join dir, file)
  end
  
end # === class Box

BOX = Box.new
`mkdir -p #{BOX.dir}`
at_exit { 
  `rm -rf #{BOX.dir}`
}

Dir.glob('spec/tests/*.rb').each { |file|
  require File.expand_path(file.sub('.rb', '')) if File.file?(file)
}
