## Developer Notes

### Building Webiva on Mac OSX

The version of the rmagick gem that Webiva depends on will no longer build against Homebrew's imagemagick package. You'll likely have imagemagick installed via homebrew for development of newer apps, and you'll want to keep it for that reason. Fortunately, homebrew also provides a legacy imagemagick package called 'imagemagick-ruby186' that does work for building older versions of rmagick.

To build rmagick for Webiva:

1. Install the legacy imagemagick package: `brew install imagemagick-ruby186`
2. Unlink your modern imagemagick: `brew unlink imagemagick`
3. Link up your old-fashioned imagemagick: `brew link imagemagick-ruby186`
4. Install rmagick: `gem install rmagick -v '2.9.2'`, or re-bundle
5. Unlink old imagemagick and link new imagemagick so that you can continue to build new versions of rmagick and other ruby interfaces to imagemagick

