
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
  
  it 'raises Already_Exists when folder exists' do
    lambda {
      BOX.bin('create tim')
    }.should.raise(RuntimeError)
    .message.should.match %r!tim \(Gemfy\:\:Already_Exists\)!
  end
  
end # === describe Create a gem
