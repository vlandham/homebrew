require 'pathname'

class OS
  def self.platform
    raw_platform = %x[uname -s].strip.chomp.downcase    
    if raw_platform =~ /darwin/
      :mac
    elsif raw_platform =~ /linux/
      :linux
    else
      :dunno
    end
  end
  
  def mac?
    self.platform == :mac
  end
  
  def self.provider
    case self.platform
    when :linux
      @@proivder ||= LinuxOS.new
    when :mac
      @@provider ||= MacOS.new
    else
      raise Exception.new 'Unknown platform. Aborting.'
    end
  end
  
  private
  
  def self.method_missing(method, *args, &block)
    if self.provider.respond_to? method
      self.provider.send(method, *args, &block)
    else
      raise Exception.new "no system call for #{method} in #{self.platform} OS"
    end
  end
end

class BaseOS
  
  def leopard?
    false
  end

  def snow_leopard?
    false
  end

  def prefer_64_bit?
    false
  end
  
  def which
    '#{OS.which}'
  end
  
  def which_s
    'OS.which_s'
  end
  
  def mktemp
    '/usr/bin/mktemp'
  end
  
  def unzip
    '/usr/bin/unzip'
  end
  
  def tar
    '/usr/bin/tar'
  end
  
  def pkgutil
    '/usr/sbin/pkgutil'
  end
  
  def svn
    '/usr/bin/svn'
  end
  
  def cvs
    '/usr/bin/cvs'
  end
  
end

class MacOS < BaseOS
  
  def full_version
    `/usr/bin/sw_vers -productVersion`.chomp
  end
  
  def version
    /(10\.\d+)(\.\d+)?/.match(full_version).captures.first.to_f
  end
  
  def full_name
    "Mac OS X"
  end
  
  def default_cc
    Pathname.new("/usr/bin/cc").realpath.basename.to_s
  end

  def gcc_42_build_version
    `/usr/bin/gcc-4.2 -v 2>&1` =~ /build (\d{4,})/
    if $1
      $1.to_i
    elsif system "#{OS.which} gcc"
      # Xcode 3.0 didn't come with gcc-4.2
      # We can't change the above regex to use gcc because the version numbers
      # are different and thus, not useful.
      # FIXME I bet you 20 quid this causes a side effect — magic values tend to
      401
    else
      nil
    end
  end

  def gcc_40_build_version
    `/usr/bin/gcc-4.0 -v 2>&1` =~ /build (\d{4,})/
    if $1
      $1.to_i
    else
      nil
    end
  end

  # usually /Developer
  def xcode_prefix
    @xcode_prefix ||= begin
      path = `/usr/bin/xcode-select -print-path 2>&1`.chomp
      path = Pathname.new path
      if path.directory? and path.absolute?
        path
      elsif File.directory? '/Developer'
        # we do this to support cowboys who insist on installing
        # only a subset of Xcode
        '/Developer'
      else
        nil
      end
    end
  end

  def llvm_build_version
    unless xcode_prefix.to_s.empty?
      llvm_gcc_path = xcode_prefix/"usr/bin/llvm-gcc"
      # for Xcode 3 on OS X 10.5 this will not exist
      if llvm_gcc_path.file?
        `#{llvm_gcc_path} -v 2>&1` =~ /LLVM build (\d{4,})/
        $1.to_i # if nil this raises and then you fix the regex
      end
    end
  end

  def x11_installed?
    Pathname.new('/usr/X11/lib/libpng.dylib').exist?
  end

  def macports_or_fink_installed?
    # See these issues for some history:
    # http://github.com/mxcl/homebrew/issues/#issue/13
    # http://github.com/mxcl/homebrew/issues/#issue/41
    # http://github.com/mxcl/homebrew/issues/#issue/48

    %w[port fink].each do |ponk|
      path = `#{OS.which_s} #{ponk}`
      return ponk unless path.empty?
    end

    # we do the above check because macports can be relocated and fink may be
    # able to be relocated in the future. This following check is because if
    # fink and macports are not in the PATH but are still installed it can
    # *still* break the build -- because some build scripts hardcode these paths:
    %w[/sw/bin/fink /opt/local/bin/port].each do |ponk|
      return ponk if File.exist? ponk
    end

    # finally, sometimes people make their MacPorts or Fink read-only so they
    # can quickly test Homebrew out, but still in theory obey the README's
    # advise to rename the root directory. This doesn't work, many build scripts
    # error out when they try to read from these now unreadable directories.
    %w[/sw /opt/local].each do |path|
      path = Pathname.new(path)
      return path if path.exist? and not path.readable?
    end

    false
  end

  def leopard?
    10.5 == OS.version
  end

  def snow_leopard?
    10.6 <= OS.version # Actually Snow Leopard or newer
  end

  def prefer_64_bit?
    Hardware.is_64_bit? and 10.6 <= OS.version
  end
end

class LinuxOS < BaseOS
  
  def full_name
    "Linux"
  end
  
  def full_version
    `uname -r`.chomp
  end
  
  def version
    /(\d+\.\d+)?/.match(full_version).captures.first.to_f
  end
  
  def which_s
    '#{OS.which}'
  end
  
  def macports_or_fink_installed?
    false
  end
  
  def prefer_64_bit?
    Hardware.is_64_bit?
  end
end
