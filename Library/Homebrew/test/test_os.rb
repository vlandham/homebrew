require 'testing_env'

require 'extend/ARGV' # needs to be after test/unit to avoid conflict with OptionsParser
ARGV.extend(HomebrewArgvExtension)

require 'test/testball'
require 'os'

class MacOnlyOS < OS
  def self.platform
    :mac
  end
end

class LinuxOnlyOS < OS
  def self.platform
    :linux
  end
end


class OSTests < Test::Unit::TestCase
  def test_platform
    assert [:linux, :mac].include?(OS.platform)
  end
  
  def test_provider
    assert [MacOS, LinuxOS].include?(OS.provider.class)
  end
end

class MacOSTests < Test::Unit::TestCase
  def test_xll
    assert MacOnlyOS.x11_installed?
  end
end

class LinuxOSTests < Test::Unit::TestCase
  def test_platform
    assert LinuxOnlyOS.platform == :linux
  end
  
  def test_x11
    assert LinuxOnlyOS.x11_installed?
  end
end