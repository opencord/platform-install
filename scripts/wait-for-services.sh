#!/bin/sh

# Wait for there to be no services in pending state
while $( juju status --format=summary|grep -q pending )
do
  sleep 10
done
