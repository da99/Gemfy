
describe "Update a gem version" do
  
  it 'bumps patch' do
    BOX.bin "create joey"
    b = BOX.down('joey') 
    b.bin "bump_patch"
    b.read("lib/joey/version.rb")[/.\d.\d.\d./].should.match %r!.0.0.2.!
  end

  it 'bumps minor' do
    BOX.bin "create joey2"
    b = BOX.down('joey2')
    b.bin "bump_minor"
    b.read("lib/joey2/version.rb")[/.\d.\d.\d./].should.match %r!.0.1.0.!
  end
  
  it 'adds version.rb to git after bump' do
    text = %*# On branch master\n#\n# Initial commit\n#\n# Changes to be committed:\n#   (use \"git rm --cached <file>...\" to unstage)\n#\n#\tnew file:   .gitignore\n#\tnew file:   Gemfile\n#\tnew file:   Rakefile\n#\tnew file:   joey2.gemspec\n#\tnew file:   lib/joey2.rb\n#\tnew file:   lib/joey2/version.rb\n#\tnew file:   spec/helper.rb\n#\tnew file:   spec/main.rb\n#*
    b = BOX.down('joey2')
    b.bin( "bump_minor" )
    b.shell('git status').should.be == text
  end
  
end # === describe Update a gem version
