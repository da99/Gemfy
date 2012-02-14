
describe "Create a gem" do
  
  it 'raises Invalid_Name if name is invalid' do
    lambda {
      Gemfy.new("yo/yo")
    }.should.raise(Gemfy::Invalid_Name)
    .message.should.match %r!yo/yo!
  end

  it 'creates a dir' do
    BOX.bin('create tim')
    File.directory?(BOX.down('tim').dir).should.be == true
  end
  
  it 'creates a spec/tests/bin.rb file' do
    BOX.chdir('tim') {
      File.file?("spec/tests/bin.rb").should == true
    }
  end
  
  it 'raises Already_Exists when folder exists' do
    lambda {
      BOX.bin('create tim')
    }.should.raise(RuntimeError)
    .message.should.match %r!tim \(Gemfy\:\:Already_Exists\)!
  end
  
  it 'adds Rake as a dependency' do
    b = BOX.down('tim')
    b.read("tim.gemspec")[%r!\w\.add_development_dependency .rake.!]
    .should.not.be == nil
  end  
  
  it 'adds Bacon as a dependency' do
    b = BOX.down('tim')
    b.read("tim.gemspec")[%r!\w\.add_development_dependency .bacon.!]
    .should.not.be == nil
  end
  
  it 'does not transform name of gem: Bacon_Colored -> BaconColored' do
    BOX.bin('create Bac_Col')
    BOX.down('Bac_Col').read('*')[%r!.{0,10}BacCol.{0,10}!].should.be == nil
  end
  
  it 'only transforms the first letter for class name: uni_Arch => Uni_Arch' do
    BOX.bin('create uni_Arch')
    BOX.down('uni_Arch').read('*')[%r!Uni_arch!].should.be == nil
  end
  
  it 'creates a .git directory' do
    File.directory?(BOX.down('tim').down('.git').dir).should.be == true
  end
  
  it 'creates a bin directory set to 750' do
    d = "samp_#{rand(1000)}"
    BOX.bin "create #{d}"
    BOX.chdir(d) {
      `stat -c %a bin`.strip
      .should == '750'
    }
  end

end # === describe Create a gem

describe ".gitignore after creation" do
  
  before do
    @ignore = lambda { |target| 
      BOX.down('tim')
        .read('.gitignore')
        .split("\n")
        .map(&:strip)
        .detect { |line| target == line }
    }
  end

  it 'must include coverage folder (rcov generated)' do
    @ignore.call('coverage').should.be == 'coverage'
  end
  
  it 'must include rdoc folder' do
    @ignore.call('rdoc').should.be == 'rdoc'
  end
  
  it 'must include .yardoc file' do
    @ignore.call('.yardoc').should.be == '.yardoc'
  end
  
end # === describe .gitignore after creation






__END__


  
  # it 'adds a gitorius remote to git repo' do
  #   BOX.down('tim').shell("git remote -v")
  #   .should == "gitorius\\tgit@gitorious.org:mu-gems/tim.git (fetch)\\ngitorius\\tgit@gitorious.org:mu-gems/tim.git (push)"
  # end
  # 
  # it 'adds a gitorius remote by lower-casing the name' do
  #   BOX.bin('create TIMM')
  #   BOX.down('TIMM').shell("git remote -v")
  #   .should == "gitorius\\tgit@gitorious.org:mu-gems/TIMM.git (fetch)\\ngitorius\\tgit@gitorious.org:mu-gems/TIMM.git (push)"
  # end
