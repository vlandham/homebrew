require 'os'

class Cleaner
  def initialize f
    @f = Formula.factory f
    [f.bin, f.sbin, f.lib].select{ |d| d.exist? }.each{ |d| clean_dir d }

    unless ENV['HOMEBREW_KEEP_INFO'].nil?
      f.info.rmtree if f.info.directory? and not f.skip_clean? f.info
    end

    # Hunt for empty folders and nuke them unless they are protected by
    # f.skip_clean? We want post-order traversal, so put the dirs in a stack
    # and then pop them off later.
    paths = []
    begin
      f.prefix.find do |path|
        paths << path if path.directory?
      end
    rescue Errno::ENOENT
    end
    
    puts "PREFIX: #{f.prefix} #{f.prefix.class}"

    paths.each do |d|
      if d.children.empty? and not f.skip_clean? d
        puts "rmdir: #{d} (empty)"
        d.rmdir
      end
    end
  end

  private

  def strip path, args=''
    return if @f.skip_clean? path
    puts "strip #{path}" if ARGV.verbose?
    path.chmod 0644 # so we can strip
    unless path.stat.nlink > 1
      system "strip", *(args+path)
    else
      path = path.to_s.gsub ' ', '\\ '

      # strip unlinks the file and recreates it, thus breaking hard links!
      # is this expected behaviour? patch does it too… still, this fixes it
      tmp = `#{OS.mktemp} -t homebrew_strip`.chomp
      begin
        `#{OS.strip} #{args} -o #{tmp} #{path}`
        `#{OS.cat} #{tmp} > #{path}`
      ensure
        FileUtils.rm tmp
      end
    end
  end

  def clean_file path
    perms = 0444
    case `file -h '#{path}'`
    when /Mach-O dynamically linked shared library/
      # Stripping libraries is causing no end of trouble. Lets just give up,
      # and try to do it manually in instances where it makes sense.
      #strip path, '-SxX'
    when /Mach-O [^ ]* ?executable/
      strip path
      perms = 0555
    when /script text executable/
      perms = 0555
    end
    path.chmod perms
  end

  def clean_dir d
     puts "cleandir: #{d} "
    d.find do |path|
      if path.directory?
        Find.prune if @f.skip_clean? path
      elsif not path.file?
        next
      elsif path.extname == '.la'
        # *.la files are stupid
        path.unlink unless @f.skip_clean? path
      elsif not path.symlink?
        clean_file path
      end
    end
  end
end
