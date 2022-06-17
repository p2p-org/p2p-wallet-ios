#!/usr/bin/ruby
#encoding: utf-8

# delete CocoaDebug from pods
path = 'Podfile'
text = File.read(path)
new_contents = text.gsub("pod 'CocoaDebug'", "# pod 'CocoaDebug'")
puts new_contents
File.open(path, "w") {|file| file.puts new_contents }

# delete extension from DebugAppDelegateService.swift
path = 'p2p_wallet/Resources/AppDelegate/DebugAppDelegateService.swift'
text = File.read(path)
new_contents = text
    .gsub("/*script_delete_flag_start*/", "/*")
    .gsub("/*script_delete_flag_end*/", "*/")
puts new_contents
File.open(path, "w") {|file| file.puts new_contents }
