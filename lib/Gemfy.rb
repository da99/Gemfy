require "Gemfy/version"
require 'Git_Repo'
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

  attr_reader :name, :current_folder, :email, :username
  def initialize raw_name
    name = raw_name.to_s.strip
    raise(Missing_Value, "name for gem") if name.empty?
    raise(Invalid_Name, name.inspect) if name[%r![^a-zA-Z0-9\-\_\.]!]
    @name           = name
    @current_folder = File.basename(File.expand_path('.'))
    @email          = git_config("email")
    @username       = git_config('name')
  end
  
  def git_config name
    val = shell("git config --get --global user.#{name}")
    if val.empty?
      raise Missing_Value, "git user.#{name}"
    end
    
    val
  end
  
  def shell cmd
    puts cmd
    val = `#{cmd} 2>&1`.to_s.strip
    if $?.exitstatus != 0
      raise Failed_Shell_Command, "Results:\n#{val}"
    end
    puts val
    val
  end
  
  def create
    raise(Already_Exists, name) if File.directory?(File.expand_path name)
    raise("Name can not be == to 'create'") if name.to_s.downcase == 'create'
    shell "mkdir -p #{folder}/lib/#{name}"
    shell "mkdir -p #{folder}/spec/tests"
    
    %w{ 
      Gemfile.tmpl
      lib--NAME.rb
      lib--NAME--version.rb
      NAME.gemspec
      NONE.gitignore
      Rakefile.tmpl
      spec--helper.rb
      spec--main.rb
    }.each { |file_name| 
      write file_name
    }
    
    shell "git init"
    shell "git add ."
    shell "git commit -m \"First commit: Gem created.\" "
    # repo.shell "git remote add gitorius git@gitorious.org:mu-gems/#{name}.git"
    
    if not testing?
      puts "\nbundle update..."
      shell "cd #{folder} && bundle update"
    end
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

  def testing?
    folder =~ %r!^/tmp!
  end

  def repo
    @repo ||= Git_Repo.new(folder)
  end

  def version_pattern
    @version_pattern ||= %r!\d+\.\d+\.\d+!
  end

  def version_rb
    @version_rb ||= "#{folder}/lib/#{name}/version.rb"
  end

  def version
    File.read(version_rb)[version_pattern]
  end

  def version_bump type
    shell "cd #{folder} && bundle exec ruby spec/main.rb"
    
    if repo.staged?
      raise Files_Uncomitted, "Commit first."
    end
    
    new_ver = case type
                
              when :patch
                pieces=version.split('.')
                patch = pieces.pop.to_i + 1
                pieces.push( patch )
                pieces.join('.')
                
              when :minor
                pieces=version.split('.')
                pieces.pop
                min = pieces.pop.to_i + 1
                pieces.push( min )
                pieces.push '0'
                pieces.join('.')
                
              else
                raise "Invalid type: #{type.inspect}"
                
              end
    
    contents = File.read( version_rb )
    File.open(version_rb, 'w') { |io|
      io.write contents.sub( version_pattern, new_ver )
    }
    
    repo.update
    repo.commit("Bump version #{type}: #{new_ver}")
    repo.tag("v#{new_ver}")
    
    release
  end
  
  def release
    return false if testing? 
    
    if name == 'Gemfy'
      shell "rake install"
      return false
    end
    
    gemspec = File.read("#{name}.gemspec")
    
    if gemspec[%r!(FIXME|TODO):!]
      raise "There are #{$1}s in .gemspec"
    end
    
    shell "gem build #{name}.gemspec"
    puts "\nPushing gem..."
    shell "gem push #{name}-#{version}.gem"
    shell "rm #{name}-#{version}.gem"
    true
  end
  
  def write filename
    templ = File.read(template(filename))
    contents = templ
      .gsub('{{name}}', name)
      .gsub('{name}', name)
      .gsub('{class_name}', name.capitalize)
      .gsub('{email}', email)
      .gsub('{username}', username)
    
    address = "#{folder}/" + (
      filename
      .sub('NAME', name)
      .sub('NONE', '')
      .sub( /.tmpl\Z/, '')
      .gsub('--', '/')
    )
      
    File.open(address, 'w') { |io|
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
          contents << "  #{obj}.add_development_dependency '#{gem_name}'"
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

  # Use ENV['pattern']= in place of 'bacon file -t pattern'
  def bacon
    args = ''
    if ENV['pattern']
      args << " -t #{ENV['pattern'].inspect}"
    end
    shell "bundle exec bacon spec/main.rb #{args}"
  end # === def bacon
  
  def git_push
    repo   = ENV['repo'] || 'gitorious'
    branch = ENV['branch'] || 'master'
    shell "git push #{repo} #{branch}"
  end
  
  # Adds Gemfile.lock to .gitignore
  def gitignore
            name = '.gitignore'
            contents = File.read(name)
            sh("echo \"Gemfile.lock\" >> #{name}") unless contents['Gemfile.lock']
            if File.directory?('.git')
              sh "git rm Gemfile.lock"
            end
  end
  
end # === class Gemfy

