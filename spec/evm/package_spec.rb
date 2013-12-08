require 'spec_helper'

describe Evm::Package do
  before do
    @foo = Evm::Package.new('foo')
    @foo.stub(:name).and_return('foo')
    @foo
  end

  describe '#current?' do
    it 'should be current if current name is same as name' do
      Evm::Package.stub(:current).and_return(@foo)
      Evm::Package.new('foo').should be_current
    end

    it 'should not be current if current name is different from name' do
      Evm::Package.stub(:current).and_return(@foo)
      Evm::Package.new('bar').should_not be_current
    end

    it 'should not be current if no current' do
      Evm::Package.stub(:current)
      Evm::Package.new('foo').should_not be_current
    end
  end

  describe '#installed?' do
    it 'should be installed if path exists' do
      File.stub(:exist?).and_return(true)

      @foo.should be_installed
    end

    it 'should not be installed if path does not exist' do
      File.stub(:exist?).and_return(false)

      @foo.should_not be_installed
    end
  end

  describe '#path' do
    it 'should be path to package path' do
      @foo.path.should == '/usr/local/evm/foo'
    end
  end

  describe '#bin' do
    it 'should be bin/emacs if linux' do
      Evm::Os.stub(:osx?).and_return(false)
      Evm::Os.stub(:linux?).and_return(true)

      @foo.bin.to_s.should == '/usr/local/evm/foo/bin/emacs'
    end

    it 'should be bin/emacs if osx and no nextstep' do
      Evm::Os.stub(:osx?).and_return(true)
      Evm::Os.stub(:linux?).and_return(false)

      File.stub(:exist?).with('/usr/local/evm/foo/Emacs.app').and_return(false)

      @foo.bin.to_s.should == '/usr/local/evm/foo/bin/emacs'
    end

    it 'should be nextstep bin if osx and nextstep' do
      Evm::Os.stub(:osx?).and_return(true)
      Evm::Os.stub(:linux?).and_return(false)

      File.stub(:exist?).with('/usr/local/evm/foo/Emacs.app').and_return(true)

      @foo.bin.should == '/usr/local/evm/foo/Emacs.app/Contents/MacOS/Emacs'
    end
  end

  describe '#use!' do
    it 'should write name to current file' do
      current_file = double('current_file')

      file = double('file')
      file.should_receive(:write).with('foo')

      File.should_receive(:open).with(current_file, 'w').and_yield(file)

      Evm::Package.stub(:current_file).and_return(current_file)

      @foo.use!
    end
  end

  describe '#install!' do
    before do
      @builder = double('builder')
      @builder.should_receive(:build!)

      File.stub(:exist?).with('/usr/local/evm/foo').and_return(true)
      File.stub(:exist?).with('/usr/local/evm/tmp').and_return(true)

      Evm::Builder.stub(:new).and_return(@builder)
    end

    it 'should create installation path if not exist' do
      File.stub(:exist?).with('/usr/local/evm/foo').and_return(false)

      Dir.should_receive(:mkdir).with('/usr/local/evm/foo')

      @foo.install!
    end

    it 'should not create installation path if exists' do
      File.stub(:exist?).with('/usr/local/evm/foo').and_return(true)

      Dir.should_not_receive(:mkdir)

      @foo.install!
    end

    it 'should create tmp path if not exist' do
      File.stub(:exist?).with('/usr/local/evm/tmp').and_return(false)

      Dir.should_receive(:mkdir).with('/usr/local/evm/tmp')

      @foo.install!
    end

    it 'should not create installation path if exists' do
      File.stub(:exist?).with('/usr/local/evm/tmp').and_return(true)

      Dir.should_not_receive(:mkdir).with('/usr/local/evm/tmp')

      @foo.install!
    end
  end

  describe '#uninstall!' do
    before do
      @foo.stub(:current?).and_return(false)
    end

    it 'should remove installation path if exists' do
      File.stub(:exist?).and_return(true)
      FileUtils.should_receive(:rm_r).with('/usr/local/evm/foo')

      @foo.uninstall!
    end

    it 'should not remove installation path if not exists' do
      File.stub(:exist?).and_return(false)
      FileUtils.should_not_receive(:rm_r)

      @foo.uninstall!
    end

    it 'should remove current file if current' do
      File.should_receive(:delete).and_return('/usr/local/evm/current')

      @foo.stub(:current?).and_return(true)

      @foo.uninstall!
    end

    it 'should not remove current file if no current' do
      File.should_not_receive(:delete)

      @foo.stub(:current?).and_return(false)

      @foo.uninstall!
    end
  end

  describe '#to_s' do
    it 'should return name' do
      @foo.to_s.should == 'foo'
    end
  end

  describe '.current_file' do
    it 'should be path to current file' do
      Evm::Package.current_file.should == '/usr/local/evm/current'
    end
  end

  describe '.current' do
    it 'should find current' do
      File.stub(:exist?).with('/usr/local/evm/current').and_return(true)
      File.stub(:read).and_return('foo')

      Evm::Package.should_receive(:find).with('foo')
      Evm::Package.current
    end

    it 'should be nil if no current file' do
      File.stub(:exist?).and_return(false)

      Evm::Package.current.should be_nil
    end
  end

  describe '.find' do
    it 'should return recipe with same name' do
      Evm::Recipe.stub(:find).and_return({})

      Evm::Package.find('foo').name.should == 'foo'
    end

    it 'should raise exception if no recipe with same name' do
      Evm::Recipe.stub(:find).and_return(nil)
      expect {
        Evm::Package.find('baz')
      }.to raise_error('No such package: baz')
    end
  end

  describe '.all' do
    it 'should return array with one package for each recipe' do
      recipes = []
      recipes << double('recipe-1', :name => 'foo')
      recipes << double('recipe-2', :name => 'bar')

      Evm::Recipe.stub(:all).and_return(recipes)

      package_1, package_2 = Evm::Package.all

      package_1.name.should == 'foo'
      package_2.name.should == 'bar'
    end
  end
end
