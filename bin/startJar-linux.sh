#!/bin/sh
if [ "$1" = "full" ]; then
  rake rawr:clean
fi
rake rawr:jar
java -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -Djruby.reify.classes=true \
  -Xms512m -Xmn128m \
-client -Xverify:none  -Xbootclasspath/a:lib/java/jruby-complete.jar -jar package/jar/broker.jar
