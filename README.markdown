# Broker

[middleman](http://middlemanapp.com/) GUI 

# License

Licensed under GPL v2.

# System Requirement

* Java Runtime
* Ruby

# Build Your Own

If you want to build your own copy, you will need [JRuby 1.6.5.1](http://jruby.org/) and [rawr](http://rawr.rubyforge.org/).

# 修改 middleman 啟動指令

開啟 ~/.broker/config 修改 middleman_command 內容, 範例如下

## 使用 rvm 

```
middleman_command: 
  init: "rvm ruby-1.9.3-p0@middleman-beta do middleman init"
  build: "rvm ruby-1.9.3-p0@middleman-beta do middleman build"
  server: "rvm ruby-1.9.3-p0@middleman-beta do middleman server"
```

## Windows + RubyInstaller 

http://tka.github.com/blog/2012/01/23/zai-windows7-zhong-shi-yong-middleman/

```
middleman_command: 
  init: middleman init
  build: middleman build
  server: middleman server -p 4567
```