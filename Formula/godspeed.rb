class Godspeed < Formula
  desc "Ultimate Full-Stack Development Environment with AI Integration"
  homepage "https://github.com/dambu07/godspeed"
  url "https://github.com/dambu07/godspeed/archive/refs/tags/v0.7.0.tar.gz"
  version "0.7.0"
  license "MIT"
  
  depends_on "bash" => :build
  depends_on "git"
  depends_on "curl"
  depends_on "jq"

  def install
    bin.install "godspeed.sh" => "godspeed"
    bash_completion.install "completions/godspeed.bash" if File.exist?("completions/godspeed.bash")
    zsh_completion.install "completions/godspeed.zsh" if File.exist?("completions/godspeed.zsh")
    man1.install "docs/godspeed.1" if File.exist?("docs/godspeed.1")
  end

  test do
    system "#{bin}/godspeed", "--version"
    system "#{bin}/godspeed", "doctor"
  end
end
