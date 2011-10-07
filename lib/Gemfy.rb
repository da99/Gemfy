require "Gemfy/version"
class Gemfy

  Missing_Value        = Class.new(RuntimeError)
  Missing_File         = Class.new(RuntimeError)
  Failed_Shell_Command = Class.new(RuntimeError)
  Already_Exists       = Class.new(RuntimeError)
  Invalid_Name         = Class.new(RuntimeError)

  attr_reader :name, :current_folder
  def initialize raw_name
    name = raw_name.to_s.strip
    raise(Missing_Value, "name for gem") if name.empty?
    raise(Invalid_Name, name.inspect) if name[%r![^a-zA-Z0-9\-\_\.]!]
    @name = name
    @current_folder = File.basename(File.expand_path('.'))
    email = git_config("email")
    username = git_config('name')
  end
  
  def git_config name
    val = shell("git config --get --global user.#{name}")
    if val.empty?
      raise Missing_Value, "git user.#{name}"
    end
    
    val
  end
  
  def shell cmd
    val = `#{cmd}`.to_s.strip
    if $?.exitstatus != 0
      raise Failed_Shell_Command, "#{cmd}"
    end
    puts cmd
    puts val
    val
  end
  
  def create
    raise(Already_Exists, name) if File.directory?(File.expand_path name)
    raise("Name can not be == to :create") if name == 'create'
    shell "bundle gem #{name}"
    shell "mkdir -p #{folder}/spec/tests"
    write 'spec--main.rb'
    write 'spec--helper.rb'
    shell "cd #{folder} && git remote add gitorius git@gitorious.org:mu-gems/#{name}.git"
  end
  
  def folder
    if current_folder == name
      File.expand_path('.')
    else
      File.expand_path(name)
    end
  end

  def bump_patch
    version_bump :patch
  end
  
  def bump_minor
    version_bump :minor
  end

  def version_bump type
    version_rb = "lib/#{name}/version.rb"
    file = (File.expand_path "#{folder}/#{version_rb}")
    pattern = %r!\d+.\d+.\d+!
    ver = File.read(file)[pattern]
    new_ver = case type
              when :patch
                pieces=ver.split('.')
                patch = pieces.pop.to_i + 1
                pieces.push( patch )
                pieces.join('.')
              when :minor
                pieces=ver.split('.')
                pieces.pop
                min = pieces.pop.to_i + 1
                pieces.push( min )
                pieces.push '0'
                pieces.join('.')
              else
                raise "Invalid type: #{type.inspect}"
              end
    contents = File.read( file )
    File.open(file, 'w') { |io|
      io.write contents.sub( pattern, new_ver )
    }
    shell "cd #{folder} && git add . && git add #{version_rb} && git status"
  end
  
  def write name
    templ = File.read(template(name))
    contents = templ.gsub('{{name}}', name)
    
    File.open("#{folder}/#{name.gsub('--', '/')}", 'w') { |io|
      io.write contents
    }
    
    contents
  end
  
  def template name
    dir = File.dirname(File.expand_path(__FILE__))
    path = File.join( dir, 'templates', name )
    raise(Missing_File, "#{path}") if !File.file?(path)
    path
  end

end # === class Gemfy

