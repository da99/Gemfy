
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
    BOX.bin('create timmy')
    File.directory?("#{BOX.down('timmy').dir}/spec/tests").should.be == true
  end
  
  it 'adds a gitorius remote to git repo' do
    BOX.bin('create tim3')
    BOX.down('tim3').shell("git remote -v").should == "gitorius\tgit@gitorious.org:mu-gems/tim3.git (fetch)\ngitorius\tgit@gitorious.org:mu-gems/tim3.git (push)"
  end
  
  it 'raises Already_Exists when folder exists' do
    lambda {
      BOX.bin('create tim4')
      BOX.bin('create tim4')
    }.should.raise(RuntimeError)
    .message.should.match %r!tim4 \(Gemfy\:\:Already_Exists\)!
  end
  
end # === describe Create a gem
