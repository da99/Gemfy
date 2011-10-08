require "Gemfy/version"
require 'Gemfy/Git_Repo'
class Gemfy

  Missing_Value        = Class.new(RuntimeError)
  Missing_File         = Class.new(RuntimeError)
  Failed_Shell_Command = Class.new(RuntimeError)
  Already_Exists       = Class.new(RuntimeError)
  Invalid_Name         = Class.new(RuntimeError)
  Files_Uncomitted     = Class.new(RuntimeError)
  Invalid_Command      = Class.new(RuntimeError)

  class << self
    
    def all *raw_args
      args = raw_args.flatten
      case args.first.to_s
      when 'add_depend'
      Dir.glob('*/*.gemspec') { |file|
        dir = File.dirname(File.expand_path(file))
        name = File.basename(dir)
        g = Gemfy.new(name)
        g.send *args
      }
      else
        raise Invalid_Command, ":#{args.first}"
      end
    end

  end # === class << self

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
    val = `#{cmd} 2>&1`.to_s.strip
    puts cmd
    if $?.exitstatus != 0
      raise Failed_Shell_Command, "Results:\n#{val}"
    end
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
    add_depend 'bacon'
    add_depend 'rake'
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

  # def nothing_to_commit? dir
  #   !!( shell("cd #{folder} && git status")['nothing to commit (working directory clean)'] )
  # end
  # 
  # def commit_pending? dir
  #   !nothing_to_commit?(dir)
  # end

  def testing?
    folder =~ %r!^/tmp!
  end

  def version_bump type
    shell "cd #{folder} && bundle exec ruby spec/main.rb"
    
    if Git_Repo.new(folder).staged?
      raise Files_Uncomitted, "Commit first."
    end
    
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
    results = shell "cd #{folder} && git add . && git add #{version_rb} && git commit -m \"Bump version #{type}: #{new_ver}\" && git tag v#{new_ver}"
    
    if testing?
      return results
    end
    
    gem_pkg = "#{name}-#{new_ver}.gem"
    mu_gems = shell("mu_gems && pwd")
    
    r = Git_Repo.new(mu_gems)
    r.reset
    r.bundle_update
    r.add( "Gemfile.lock " )
    r.commit("Added gem: #{name}")
    r.push("heroku")
  end
  
  def write filename
    templ = File.read(template(filename))
    contents = templ.gsub('{{name}}', name)
    
    File.open("#{folder}/#{filename.gsub('--', '/')}", 'w') { |io|
      io.write contents
    }
    
    contents
  end
  
  def template filename
    path = File.join( File.dirname(__FILE__), 'templates', filename )
    raise(Missing_File, "#{path}") if !File.file?(path)
    path
  end
  
  def add_depend gem_name
    file = (folder + "/#{name}.gemspec")
    orig = File.read(file).strip
    found = false
    contents = []
    orig.split("\n").each { |line|
      if line[%r!(.+)\.require_paths!]
        found = true
        obj = $1
        if not orig[%r!dependency\s+.#{gem_name}[\"\']!]
          contents << "  #{$1}.add_development_dependency '#{gem_name}'"
        end
      end
      contents << line
    }
    
    if not found
      raise "Could not find .require_paths as a starting point."
    end
    
    File.open(file, 'w') { |io|
      io.write contents.join("\n")
    }
  end

end # === class Gemfy

