require 'formula'

class Ffmpeg < Formula
  url 'http://ffmpeg.org/releases/ffmpeg-0.6.2.tar.bz2'
  homepage 'http://ffmpeg.org/'
  sha1 'd4e464d4111971b9cef10be7a1efa3677a899338'

  head 'git://git.videolan.org/ffmpeg.git'

  depends_on 'x264' => :optional
  depends_on 'faac' => :optional
  depends_on 'faad2' => :optional
  depends_on 'lame' => :optional
  depends_on 'theora' => :optional
  depends_on 'libvorbis' => :optional
  depends_on 'libogg' => :optional
  depends_on 'libvpx' => :optional
  depends_on 'xvid' => :optional

  def install
    args = ["--disable-debug",
            "--prefix=#{prefix}",
            "--enable-shared",
            "--enable-pthreads",
            "--enable-nonfree",
            "--enable-gpl",
            "--disable-indev=jack"]

    args << "--enable-libx264" if Formula.factory('x264').installed?
    args << "--enable-libfaac" if Formula.factory('faac').installed?
    args << "--enable-libmp3lame" if Formula.factory('lame').installed?
    args << "--enable-libtheora" if Formula.factory('theora').installed?
    args << "--enable-libvorbis" if Formula.factory('libvorbis').installed?
    args << "--enable-libvpx" if Formula.factory('libvpx').installed?
    args << "--enable-libxvid" if Formula.factory('xvid').installed?

    unless ARGV.build_head?
      args << "--enable-libfaad" if Formula.factory('faad2').installed?
    end

    # For 32-bit compilation under gcc 4.2, see:
    # http://trac.macports.org/ticket/20938#comment:22
    if OS.snow_leopard? and Hardware.is_32_bit?
      ENV.append_to_cflags "-mdynamic-no-pic"
    end

    system "./configure", *args

    if OS.prefer_64_bit?
      inreplace 'config.mak' do |s|
        shflags = s.get_make_var 'SHFLAGS'
        if shflags.gsub!(' -Wl,-read_only_relocs,suppress', '')
          s.change_make_var! 'SHFLAGS', shflags
        end
      end
    end

    write_version_file if ARGV.build_head?

    system "make install"
  end

  # Makefile expects to run in git repo and generate a version number
  # with 'git describe' command (see version.sh) but Homebrew build
  # runs in temp copy created via git checkout-index, so 'git describe'
  # does not work. Work around by writing VERSION file in build directory
  # to be picked up by version.sh.  Note that VERSION file will already
  # exist in release versions, so this only applies to git HEAD builds.
  def write_version_file
    return if File.exists?("VERSION")
    git_tag = "UNKNOWN"
    Dir.chdir(cached_download) do
      ver = `./version.sh`.chomp
      if not $?.success? or ver == "UNKNOWN"
        # fall back to git
        ver = `git describe --tags --match N --always`.chomp
        if not $?.success?
          opoo "Could not determine build version from git repository - set to #{git_tag}"
        else
          git_tag = "git-#{ver}"
        end
      else
        git_tag = ver
      end
    end
    File.open("VERSION","w") {|f| f.puts git_tag}
  end

end
