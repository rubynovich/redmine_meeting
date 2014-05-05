#!/bin/bash

git add . && \
git commit -m "tmp: squash me" && \
git push origin send_protocol_to_all && \
ssh aantonov@192.168.80.230 "cd /opt/redmine-2.3/plugins/redmine_meeting && git checkout send_protocol_to_all && git pull origin send_protocol_to_all && sudo service nginx stop && sleep 1 && sudo service nginx start" 
