
describe "Update a gem version" do

  it "won't tag git if there are pending files to be committed." do
    BOX.bin("create Joey") { |b|
      lambda {
        b.shell "echo 'test' > test.rb"
        b.bin "bump_patch"
      }.should.raise(RuntimeError)
      .message.should.match %r!Commit first. \(Gemfy::Files_Uncomitted\)!
    }
  end
  
  it "raises an error if there are files with :puts" do
    BOX.bin("create puts") { |b|
      b.append "lib/puts.rb", "puts 'something'"
      lambda {
        b.bin "bump_patch"
      }.should.raise(RuntimeError)
      .message.should.match %r!Files with puts: !
    }
  end
  
  it "raises an error if there are files with #{'BINDING.PRY'.downcase}" do
    BOX.bin("create Bpry") { |b|
      File.write "lib/pry.rb", "BINDING.PRY".downcase

      lambda {
        b.bin "bump_patch"
      }.should.raise(RuntimeError)
      .message.should.match %r!Files with BINDING.pry: !i
    }
  end
  
  it "raises an error if there are files with double tabs" do
    BOX.bin("create tabs") { |b|
      b.append "spec/main.rb", "\t\t"
      lambda {
        b.bin "bump_patch"
      }.should.raise(RuntimeError)
      .message.should.match %r!Files with tabs: !
    }
  end

  it "won't tag git if there are todos in .gemspec" do
    BOX.bin("create todo01") { |b|
      lambda {
        b.bin "bump_patch"
      }.should.raise(RuntimeError)
      .message.should.match %r!There are TODOs in todo01.gemspec!

      b.shell("git tag -l").should.be == ''
    }
  end
  
  it "won't tag git if there are fixmes in .gemspec" do
    BOX.bin("create fixme01") { |b|
      b.fix_todos
      b.append "fixme01.gemspec", '# FIXME: '
      b.git_commit 'Added a FIXME to gemspec file.'
      lambda {
        b.bin "bump_patch"
      }.should.raise(RuntimeError)
      .message.should.match %r!There are FIXMEs in fixme01.gemspec!

      b.shell("git tag -l").should.be == ''
    }
  end

  it 'tags git after bump' do
    BOX.chdir('Joey')  { |b|
      b.fix_gemspec

      b.bin 'bump_minor'
      b.shell( "git tag -l" ).should.be == "v0.1.0"
    }
  end
  
  it 'raises error if previous commit was a tag' do
    BOX.bin("create already_tagged") { |b|
      b.fix_gemspec
      b.bin 'bump_minor'
      lambda { b.bin 'bump_minor' }.should.raise(RuntimeError)
      .message.should.match %r!Previous commit already tagged!
    }
  end
  
  it 'commits after bump' do
    BOX.bin("create committed_bump") { |b|
      b.fix_gemspec
      b.bin 'bump_minor'
      b.shell("git status")['nothing to commit'].should.be == 'nothing to commit'
    }
  end

  it 'bumps minor' do
    BOX.bin("create bump_minor01") { |b|
      b.fix_gemspec
      b.bin "bump_minor"
      b.read("lib/bump_minor01/version.rb")[/\d.\d.\d/].should == "0.1.0"
    }
  end

  it 'bumps patch' do
    BOX.bin("create bump_patch01") { |b|
      b.fix_gemspec
      b.bin "bump_patch"
      b.read("lib/bump_patch01/version.rb")[/\d.\d.\d/].should == "0.0.2"
    }
  end

  it 'bumps major' do
    BOX.bin("create major01") { |b|
      b.fix_gemspec
      b.bin "MaJoR"
      b.read("lib/major01/version.rb")[/\d.\d.\d/].should == "1.0.0"
    }
  end
  
  it 'git tags major with "Bump version major: \\d.\\d.\\d"' do
    BOX.chdir('major01') { |b|
      b.shell("git log -n 1 --oneline").should.match %r@Bump version major: \d\.\d\.\d@
    }
  end

  it 'adds version.rb to git after bump' do
    BOX.chdir('Joey') { |b|
      b.shell('git status')['nothing to commit'].should.be == 'nothing to commit'
    }
  end
  
  it 'fails to bump version if Bacon specs are not met.' do
    name = "Joey_Fail"
    BOX.bin("create #{name}")
    b = BOX.chdir( name )
    old_tags = b.shell("git tag -l")
    File.open(b.dir + '/spec/tests/fail.rb', 'w') { |io|
      io.write %~
        describe 'fails' do
          it 'fails' do
            false.should.be == true
          end
        end
      ~
    }
    
    b.shell "git add ."
    b.shell "git commit -m \"Added test.\""
    m = lambda {
      b.bin('bump_minor')
    }.should.raise(RuntimeError)
    
    m.message.should.match %r!failed\n\t/tmp/Gemfy/[a-zA-Z0-9\-\_]+/#{name}/spec/tests/fail.rb:4!
      
    b.shell("git tag -l").should.be == old_tags
  end
  
  it 'applies command to all gems' do
    BOX.bin 'create Joey2'
    b1 = BOX.chdir('Joey')
    b2 = BOX.chdir('Joey2')
    
    BOX.bin 'all add_depend rEstEr'
    b1.read('Joey.gemspec')['rEstEr'].should.be == 'rEstEr'
    b2.read('Joey2.gemspec')['rEstEr'].should.be == 'rEstEr'
  end
  
  it 'raises Invalid_Command if :bump_minor is applied to all gems' do
    lambda {
      BOX.bin("all bump_minor")
    }.should.raise(RuntimeError)
    .message.should.match %r!:bump_minor \(Gemfy::Invalid_Command\)!
  end
  
  it 'does not add another dependency if it already exists' do
    BOX.chdir('Joey') { |b|
      b.bin 'add_depend rEstEr'
      b.bin 'add_depend rEstEr'
      b.read('Joey.gemspec').scan(%r!rEstEr!).should == ['rEstEr']
    }
  end
  
end # === describe Update a gem version
