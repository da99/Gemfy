
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
  
  it 'tags git after bump' do
    b = BOX.down('joey') 
    b.shell "git add . && git add -u && git commit -m \"First commit.\""
    
    b.bin 'bump_minor'
    b.shell( "git tag -l" ).should.be == "v0.1.0"
  end
  
  it 'commits after bump' do
    b = BOX.down('joey') 
    b.bin 'bump_minor'
    b.shell("git status")['nothing to commit'].should.be == 'nothing to commit'
  end

  it 'bumps patch' do
    b = BOX.down('joey') 
    b.bin "bump_patch"
    b.read("lib/joey/version.rb")[/.\d.\d.\d./].should.match %r!.0.2.1.!
  end

  it 'bumps minor' do
    b = BOX.down('joey')
    b.bin "bump_minor"
    b.read("lib/joey/version.rb")[/.\d.\d.\d./].should.match %r!.0.3.0.!
  end

  it 'adds version.rb to git after bump' do
    b = BOX.down('joey')
    b.shell('git status')['nothing to commit'].should.be == 'nothing to commit'
  end
  
  it 'fails to bump version if Bacon specs are not met.' do
    b = BOX.down('joey')
    File.open(b.dir + '/spec/tests/fail.rb', 'w') { |io|
      io.write %~
        describe 'fails' do
          it 'fails' do
            false.should.be == true
          end
        end
      ~
    }
    lambda {
      b.bin('bump_minor')
    }.should.raise(RuntimeError)
    .message.should.match %r!\[FAILED\]\n\nBacon::Error: false.==\(true\) failed\n\t/tmp/Gemfy/[a-zA-Z0-9\-\_]+/joey/spec/tests/fail.rb:4!
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
