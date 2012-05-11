require "Gemfy/version"
require 'Git_Repo'
require 'Exit_0'

class Gemfy

  Missing_Value        = Class.new(RuntimeError)
  Missing_File         = Class.new(RuntimeError)
  Failed_Shell_Command = Class.new(RuntimeError)
  Already_Exists       = Class.new(RuntimeError)
  Invalid_Name         = Class.new(RuntimeError)
  Files_Uncomitted     = Class.new(RuntimeError)
  Invalid_Command      = Class.new(RuntimeError)
  Already_Tagged       = Class.new(RuntimeError)
  Tabbed_Files         = Class.new(RuntimeError)
  Puts_Files           = Class.new(RuntimeError)
  Pry_Debugging        = Class.new(RuntimeError)
  
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
    val = quiet_shell("git config --get --global user.#{name}")
    if val.empty?
      raise Missing_Value, "git user.#{name}"
    end
    
    val
  end
  
  def print *args
    args.each { |a|
      super a, "\n"
    }
  end

  def log *raw_args
    args = raw_args.map { |s| s[' '] ? s.inspect : s }
    shell "git log -n 5 --oneline --decorate=short #{ args.join ' '}"
  end

  def readme
    file = "README.md"
    raise ArgumentError, "#{file} not found" unless File.exists?(file)
    
    tmp_dir = "/tmp/Gemfy_Markdown"
    tmp = "#{tmp_dir}/file.#{rand 1000}.md"
    `mkdir -p #{tmp_dir}`
    
    File.write(tmp, %~
<html>
<head>
  <link href="http://kevinburke.bitbucket.org/markdowncss/markdown.css" rel="stylesheet"></link>
  <style type="text/css">
    p, ul, ol {
      font-size: 20px;
      line-height: 24px;
      max-width: 900px;
    }
    code {
      font-size: 16px;
      background: #DAF0E6;
      color: black;
      display: block;
      padding: 8px 8px;
      border-radius: 3px;
    }
  </style>
  <title>#{file}</title>
</head>
  <body>
    #{ `cat #{file} | redcarpet `}
  </body>
</html
    ~)
    
    exec "cat #{tmp} | bcat -h"
  end

  def quiet_shell cmd
    val = `#{cmd} 2>&1`.to_s.strip
    if $?.exitstatus != 0
      raise Failed_Shell_Command, "Results:\n#{val}"
    end
    val
  end

  def shell cmd, msg = nil
    print cmd
    print(msg, "\n") if msg
    val = quiet_shell(cmd)
    print val
    val
  end
  
  def create_bin type, name = nil
    name ||= self.name
    path = "bin/#{name}"
    raise ArgumentError, "File already exists: #{path}" if File.exists?(path)

    Exit_0 %^
      echo "#!/usr/bin/env #{type}" >> "#{path}"
      echo "# -*- #{type} -*-"      >> "#{path}"
      echo "# "                     >> "#{path}"
      echo ""                       >> "#{path}" 
      echo ""                       >> "#{path}"
      chmod +x                         "#{path}"
    ^
    print "#{path}\n"
  end

  def create
    raise(Already_Exists, name) if File.directory?(File.expand_path name)
    raise("Name can not be == to 'create'") if name.to_s.downcase == 'create'
    shell "mkdir -p #{folder}/lib/#{name}"
    shell "mkdir -p #{folder}/spec/lib"
    shell "mkdir -p #{folder}/bin"
    shell "chmod 750 #{folder}/bin"
    
    %w{ 
      Gemfile.tmpl
      lib--NAME.rb
      lib--NAME--version.rb
      NAME.gemspec
      NONE.gitignore
      Rakefile.tmpl
      README.md
      spec--lib--main.rb
      spec--bin.rb
      spec--NAME.rb
    }.each { |file_name| 
      write file_name
    }
    
    shell "
      cd #{folder} 
      git init
      git add .
      git commit -m \"First commit: Gem created.\" 
    ".strip.split("\n").join(" && ")
    # repo.shell "git remote add gitorius git@gitorious.org:mu-gems/#{name}.git"
    
    if not testing?
      print "\nbundle update..."
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

  def MaJoR
    version_bump :MaJoR
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
    unless File.exists?('config/allow_puts.txt')
      puts_files = Dir.glob("**/*.rb").select { |file|
        !file['spec/'] && 
          File.read(file)[/puts[\s\(]/]
      }
      unless puts_files.empty?
        raise Puts_Files, "Files with puts: #{puts_files.join ", "}"
      end
    end
    
    tabbed_files = Dir.glob("**/*.rb").select { |file|
      File.read(file)["\t\t"]
    }
    unless tabbed_files.empty?
      raise Tabbed_Files, "Files with tabs: #{tabbed_files.join(", ")}"
    end

    pry_files = Dir.glob('**/*.rb').select { |file|
      File.read(file)["BINDING.PRY".downcase]
    }
    unless pry_files.empty?
      raise Pry_Debugging, "Files with #{'BINDING.PRY'.downcase}: #{pry_files.join(", ")}"
    end

    previous = shell(%~ git log -n 1 --oneline --decorate=full ~)
    if previous['tag: refs/tags/v']
      raise Already_Tagged, "Previous commit already tagged: #{previous}"
    end
    
    bacon
    
    if repo.staged?
      raise Files_Uncomitted, "Commit first."
    end

    check_gemspec
    
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
                
              when :MaJoR
                pieces=version.split('.')
                pieces.pop
                pieces.pop
                m = pieces.pop.to_i + 1
                pieces.push( m )
                pieces.push '0'
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
    repo.commit("Bump version #{type.downcase}: #{new_ver}")
    repo.tag("v#{new_ver}")
    
    release
  end
  
  def check_gemspec
    gemspec = File.read("#{name}.gemspec")
    
    if gemspec[%r!(FIXME|TODO):!]
      raise "There are #{$1}s in #{name}.gemspec"
    end
  end

  def release
    check_gemspec
    return false if testing? 
    
    if File.file?("config/local_only.txt")
      shell "rake install"
      shell "rm pkg/#{name}-#{version}.gem"
      return false
    end
    
    shell "gem build #{name}.gemspec"
    print "\nPushing gem..."
    shell "gem push #{name}-#{version}.gem"
    shell "rm #{name}-#{version}.gem"
    
    if `git remote -v`["origin"]
      shell "git push origin v#{version}" 
      shell "git push" 
    end
    
    true
  end
  
  def origin short_name
    if short_name.downcase["git"]
      name = "github:"
      dir  = "#{File.basename `pwd`.strip}"
    else
      name = "ssh://bitbucket/"
      dir  = "#{File.basename(`pwd`.strip).downcase}"
    end
    
    shell "git remote add origin #{name}da99/#{dir}.git"
    shell "git push -u origin master"
  end

  def write filename
    templ = File.read(template(filename))
    contents = templ
      .gsub('{{name}}', name)
      .gsub('{name}', name)
      .gsub('{class_name}', name.sub( %r!.! ) { |c| c.capitalize } )
      .gsub('{escape_underscore_class_name}',  name.sub( %r!.! ) { |c| c.capitalize }.gsub("_", "\\_") )
      .gsub('{escaped_underscore_class_name}', name.sub( %r!.! ) { |c| c.capitalize }.gsub("_", "\\_") )
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
  def bacon args = []
    cmd = bacon_cmd args
    shell cmd, "\nPlease wait while tests run..."
  end # === def bacon
  
  def bacon_cmd args=[]
    main = [
      Dir.glob("./spec*/**/main.rb"),
      Dir.glob("./spec*/lib*/**/main.rb")
    ].flatten.first

    raise ArgumentError, "No spec main.rb file found." unless main

    if ENV['pattern']
      args << " -t "
      args << "#{ENV['pattern'].inspect}"
    end
    
    cmd = "bundle exec bacon #{main} #{args.map(&:inspect).join ' '}"
  end

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
  
  def local_only
    shell("mkdir -p config && touch config/local_only.txt")
  end

end # === class Gemfy

