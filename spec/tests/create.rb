
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
  
  it 'creates a spec/tests dir' do
    File.directory?("#{BOX.down('tim').dir}/spec/tests").should.be == true
  end
  
  it 'adds a gitorius remote to git repo' do
    BOX.down('tim').shell("git remote -v")
    .should == "gitorius\tgit@gitorious.org:mu-gems/tim.git (fetch)\ngitorius\tgit@gitorious.org:mu-gems/tim.git (push)"
  end
  
  it 'adds a gitorius remote by lower-casing the name' do
    BOX.bin('create TIMM')
    BOX.down('TIMM').shell("git remote -v")
    .should == "gitorius\tgit@gitorious.org:mu-gems/TIMM.git (fetch)\ngitorius\tgit@gitorious.org:mu-gems/TIMM.git (push)"
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
  
end # === describe Create a gem
