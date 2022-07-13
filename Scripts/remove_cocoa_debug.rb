#!/usr/bin/ruby
#encoding: utf-8

# delete CocoaDebug from pods
path = 'Podfile'
text = File.read(path)
new_contents = text.gsub("pod 'CocoaDebug'", "# pod 'CocoaDebug'")
puts new_contents
File.open(path, "w") {|file| file.puts new_contents }
