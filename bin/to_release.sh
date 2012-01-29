#!/bin/bash 
cp packages/broker.windows* packages/broker.windows.$1.zip
cp packages/broker.osx* packages/broker.osx.$1.zip
cp packages/broker.linux* packages/broker.linux.$1.zip
ls -lot packages
