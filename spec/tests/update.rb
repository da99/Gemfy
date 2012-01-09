
describe "Update a gem version" do

  it "won't tag git if there are pending files to be committed." do
    BOX.bin "create joey"
    b = BOX.down('joey')
    lambda {
      b.shell "echo 'test' > test.rb"
      b.bin "bump_patch"
    }.should.raise(RuntimeError)
    .message.should.match %r!Commit first. \(Gemfy::Files_Uncomitted\)!
  end
  
  it "raises an error if there are files with double tabs" do
    BOX.bin "create tabs"
    b = BOX.down("tabs")
    lambda {}.should.raise(RuntimeError)
    .message.should.match %r!files with tabs!
  end

  it "won't tag git if there are todos in .gemspec" do
    BOX.bin "create todo01"
    b = BOX.down('todo01')
    lambda {
      b.bin "bump_patch"
    }.should.raise(RuntimeError)
    .message.should.match %r!There are TODOs in todo01.gemspec!
    
    b.shell("git tag -l").should.be == ''
  end
  
  it "won't tag git if there are fixmes in .gemspec" do
    BOX.bin "create fixme01"
    b = BOX.down('fixme01')
    b.fix_todos
    b.append "fixme01.gemspec", '# FIXME: '
    b.git_commit 'Added a FIXME to gemspec file.'
    lambda {
      b.bin "bump_patch"
    }.should.raise(RuntimeError)
    .message.should.match %r!There are FIXMEs in fixme01.gemspec!
    
    b.shell("git tag -l").should.be == ''
  end

  it 'tags git after bump' do
    b = BOX.down('joey') 
    b.fix_gemspec
    
    b.bin 'bump_minor'
    b.shell( "git tag -l" ).should.be == "v0.1.0"
  end
  
  it 'raises error if previous commit was a tag' do
    BOX.bin "create already_tagged"
    b = BOX.down('already_tagged') 
    b.fix_gemspec
    
    b.bin 'bump_minor'
    lambda { b.bin 'bump_minor' }.should.raise(RuntimeError)
    .message.should.match %r!Previous commit already tagged!
  end
  
  it 'commits after bump' do
    BOX.bin "create committed_bump"
    b = BOX.down('committed_bump') 
    b.fix_gemspec
    b.bin 'bump_minor'
    b.shell("git status")['nothing to commit'].should.be == 'nothing to commit'
  end

  it 'bumps patch' do
    BOX.bin "create bump_patch01"
    b = BOX.down('bump_patch01') 
    b.fix_gemspec
    
    b.bin "bump_patch"
    b.read("lib/bump_patch01/version.rb")[/\d.\d.\d/].should == "0.0.2"
  end

  it 'bumps minor' do
    BOX.bin "create bump_minor01"
    b = BOX.down('bump_minor01') 
    b.fix_gemspec
    b.bin "bump_minor"
    b.read("lib/bump_minor01/version.rb")[/\d.\d.\d/].should == "0.1.0"
  end

  it 'adds version.rb to git after bump' do
    b = BOX.down('joey')
    b.shell('git status')['nothing to commit'].should.be == 'nothing to commit'
  end
  
  it 'fails to bump version if Bacon specs are not met.' do
    name = "joey"
    b = BOX.down( name )
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
    lambda {
      b.bin('bump_minor')
    }.should.raise(RuntimeError)
    .message.should.match %r!\[FAILED\]\e\[0m\n\nBacon::Error: false.==\(true\) failed\n\t/tmp/Gemfy/[a-zA-Z0-9\-\_]+/#{name}/spec/tests/fail.rb:4!
      
    b.shell("git tag -l").should.be == old_tags
  end
  
  it 'applies command to all gems' do
    BOX.bin 'create joey2'
    b1 = BOX.down('joey')
    b2 = BOX.down('joey2')
    
    BOX.bin 'all add_depend rEstEr'
    b1.read('joey.gemspec')['rEstEr'].should.be == 'rEstEr'
    b2.read('joey2.gemspec')['rEstEr'].should.be == 'rEstEr'
  end
  
  it 'raises Invalid_Command if :bump_minor is applied to all gems' do
    lambda {
      BOX.bin("all bump_minor")
    }.should.raise(RuntimeError)
    .message.should.match %r!:bump_minor \(Gemfy::Invalid_Command\)!
  end
  
  it 'does not add another dependency if it already exists' do
    b = BOX.down('joey')
    b.bin 'add_depend rEstEr'
    b.bin 'add_depend rEstEr'
    b.read('joey.gemspec').scan(%r!rEstEr!).should == ['rEstEr']
  end
  
end # === describe Update a gem version
