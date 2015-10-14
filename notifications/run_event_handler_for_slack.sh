#!/bin/bash
# temporarily link it to the jruby platform because we depend on torquebox to receive the messages
export JAVA_HOME="$BRPM_HOME/lib/jre"
export JRUBY_HOME="$BRPM_HOME/lib/jruby"
export GEM_HOME="$BRPM_HOME/modules"

export PATH="$GEM_HOME/bin:$JRUBY_HOME/bin:$PATH"

# mandatory settings
export EVENT_HANDLER_BRPM_HOST=localhost

export EVENT_HANDLER_MESSAGING_PORT=5445
export EVENT_HANDLER_MESSAGING_USERNAME=msguser
export EVENT_HANDLER_MESSAGING_PASSWORD=???

# custom settings
export EVENT_HANDLER_SLACK_TOKEN=???
export EVENT_HANDLER_SLACK_CHANNEL=???
export EVENT_HANDLER_BRPM_URL=http://public_server:port
export EVENT_HANDLER_BRPM_TOKEN=???

jruby $(dirname $0)/brpm_event_notifier.rb
