require 'extend/pathname'
require 'extend/ARGV'
require 'extend/string'
require 'exceptions'
require 'compatibility'
require 'os'
require 'utils'

ARGV.extend(HomebrewArgvExtension)

HOMEBREW_WWW = 'http://vlandham.github.com/homebrew/'

if OS.mac?
  HOMEBREW_CACHE = if Process.uid == 0
    # technically this is not the correct place, this cache is for *all users*
    # so in that case, maybe we should always use it, root or not?
    Pathname.new("/Library/Caches/Homebrew")
  else
    Pathname.new("~/Library/Caches/Homebrew").expand_path
  end
else
  HOMEBREW_CACHE = Pathname.new("#{ENV['HOME']}/.homebrew/cache")
end

if not defined? HOMEBREW_BREW_FILE
  HOMEBREW_BREW_FILE = ENV['HOMEBREW_BREW_FILE'] || `which brew`.chomp
end

HOMEBREW_PREFIX = Pathname.new(HOMEBREW_BREW_FILE).dirname.parent # Where we link under
HOMEBREW_REPOSITORY = Pathname.new(HOMEBREW_BREW_FILE).realpath.dirname.parent # Where .git is found

# Where we store built products; /usr/local/Cellar if it exists,
# otherwise a Cellar relative to the Repository.
HOMEBREW_CELLAR = if (HOMEBREW_PREFIX+"Cellar").exist?
  HOMEBREW_PREFIX+"Cellar"
else
  HOMEBREW_REPOSITORY+"Cellar"
end

RECOMMENDED_LLVM = 2326
if OS.mac?
  RECOMMENDED_GCC_40 = (OS.version >= 10.6) ? 5494 : 5493
  RECOMMENDED_GCC_42 = (OS.version >= 10.6) ? 5664 : 5577
else
  RECOMMENDED_GCC_40 = 4
  RECOMMENDED_GCC_42 = 4
end

FORMULA_META_FILES = %w[README README.md ChangeLog COPYING LICENSE LICENCE COPYRIGHT AUTHORS]
PLEASE_REPORT_BUG = "#{Tty.white}Please report this bug: #{Tty.em}https://github.com/mxcl/homebrew/wiki/new-issue#{Tty.reset}"
