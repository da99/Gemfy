
require File.expand_path('spec/helper')
require 'Gemfy'
require 'Bacon_Colored'
require 'Bacon_FS'
class Box
  
  GEM_NAME = File.expand_path('.').split('/').reverse.detect { |f| !f.strip.empty? }
  TMP      = "/tmp/#{GEM_NAME}"
  TEMP     = "#{TMP}/rand_#{rand(1000)}"
  BIN      = File.expand_path('.') + '/bin'
  BINARY   = File.join(BIN, GEM_NAME.upcase)

  attr_reader :dir
  
  def initialize name = :default
    if name === :default
      @dir = TEMP
      @name = ''
    else
      @name = name
      @dir = File.join(TEMP, name)
    end
  end

  def chdir path = nil
    Dir.chdir(File.join *([dir, path].compact) ) { yield }
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
  
  def fix_todos
    fix_gemspec 'TODO'
  end
  
  def fix_fixmes
    fix_gemspec 'FIXME'
  end

  def fix_gemspec *args
    args = %w{ TODO FIXME } if args.empty?
    altered = nil
    gemspec = Dir.glob("#{dir}/*.gemspec").first
    
    raise "No gemspec found: #{dir}" unless gemspec
    args.each { |str|

      orig = File.read(gemspec)
      content  = orig.gsub("#{str}:", "Done #{rand(1000)}")
      altered ||= (orig != content)
      
      File.open( gemspec, 'w' ) { |io|
        io.write(content)
      }
      
    }
    
    if altered
      git_commit "Updated gemspec file."
    end
  end
  
  def git_commit msg
      shell %! git add . && git add -u && git commit -m #{msg.inspect} !
  end
  
  def bin raw_cmd
    shell "#{BINARY} #{raw_cmd}"
  end
  
  def down name
    Box.new(File.join @name, name)
  end
  
  def read file
    case file
    when '*'
      Dir.glob(File.join(dir, '**/*')).map { |addr|
        if File.file?(addr)
          File.read(addr)
        else
          nil
        end
      }.compact.join("\n")
    else
      File.read(File.join dir, file )
    end
  end
  
  def append file, ending
    content = read(file) + "\n#{ending}"
    File.open("#{dir}/#{file}", 'w') { |io|
      io.write content
    }
  end
  
end # === class Box

BOX = Box.new

Dir.glob("#{Box::TMP}/*").each { |obj|
  `rm -rf #{obj}` if File.directory?(obj)
}
`mkdir -p #{BOX.dir}`

# ======== Include the tests.
if ARGV.size > 1 && ARGV[1, ARGV.size - 1].detect { |a| File.exists?(a) }
  # Do nothing. Bacon grabs the file.
else
  Dir.glob('spec/tests/*.rb').each { |file|
    require File.expand_path(file.sub('.rb', '')) if File.file?(file)
  }
end
