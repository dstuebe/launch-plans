#!/bin/bash

# git version: cookbooks come from git
# Set the repository here

GIT_URL="git://github.com/ooici/dt-data.git"
GIT_REF="origin/HEAD"

# ========================================================================

if [ ! -d /opt ]; then 
  mkdir /opt
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

if [ -d /opt/dt-data ]; then
  (cd /opt/dt-data && git fetch)
  if [ $? -ne 0 ]; then
      exit 1
  fi
else
  (cd /opt && git clone $GIT_URL )
  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

(cd /opt/dt-data && git reset --hard $GIT_REF )
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Retrieved the dt-data repository, HEAD is currently:"
(cd /opt/dt-data && git rev-parse HEAD)
echo ""

mkdir -p /opt/dt-data/run
if [ $? -ne 0 ]; then
  exit 1
fi

mv bootconf.json /opt/dt-data/run/chefroles.json
if [ $? -ne 0 ]; then
  exit 1
fi

cat >> chefconf.rb << "EOF"
cookbook_path "/opt/dt-data/cookbooks"
log_level :info
file_store_path "/opt/dt-data/tmp"
file_cache_path "/opt/dt-data/tmp"
Chef::Log::Formatter.show_time = false

EOF

mv chefconf.rb /opt/dt-data/run/chefconf.rb
if [ $? -ne 0 ]; then
  exit 1
fi


cat >> rerun-chef.sh << "EOF"
#!/bin/bash
CHEFLEVEL="info"
if [ "X" != "X$1" ]; then
  CHEFLEVEL=$1
fi
chef-solo -l $CHEFLEVEL -c /opt/dt-data/run/chefconf.rb -j /opt/dt-data/run/chefroles.json
exit $?
EOF

chmod +x rerun-chef.sh
if [ $? -ne 0 ]; then
  exit 1
fi

mv rerun-chef.sh /opt/rerun-chef.sh
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Running chef-solo"
/opt/rerun-chef.sh #debug
if [ $? -ne 0 ]; then
  exit 1
fi
