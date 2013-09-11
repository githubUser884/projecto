#!/bin/bash

if [ -f /home/vagrant/installed ]; then
echo "Setup already completed.. skipping. To run this again, remove /home/vagrant/installed"
  exit 0
fi

# getting required packages
apt-get update
apt-get install -y python-software-properties python g++ make
add-apt-repository ppa:chris-lea/node.js
apt-get update
apt-get install -y build-essential python-dev automake libtool autoconf pkg-config
apt-get install -y nodejs git subversion

# Getting convenient packages
apt-get install -y nginx

# Install pip
cd /tmp
wget http://python-distribute.org/distribute_setup.py
python distribute_setup.py
easy_install pip

# Installing LevelDB as it is a bitch to do.
cd /tmp
svn checkout http://py-leveldb.googlecode.com/svn/trunk/ py-leveldb-read-only
cd py-leveldb-read-only
./compile_leveldb.sh
python setup.py build
python setup.py install

# Setup project directory.
cd /projecto
mkdir -p databases
mkdir -p userfiles

# Install additional requirements
cd /home/vagrant # weird pip src directory is interfering if we are in /projecto
pip install -r /projecto/requirements.txt
npm install -g uglify-js

# Configuration for nginx. You can set the "projecto" to point to 192.168.33.10
# on your host machine.
cat >/etc/nginx/sites-available/projecto <<EOL
server {
    listen       80;
    server_name  projecto;

    access_log  off;
    error_log off;

    location / {
        proxy_pass         http://127.0.0.1:8800/;
        proxy_redirect     off;

        proxy_set_header   Host             \$host;
        proxy_set_header   X-Real-IP        \$remote_addr;
        proxy_set_header   X-Forwarded-For  \$proxy_add_x_forwarded_for;
        proxy_max_temp_file_size 0;

        client_max_body_size       10m;
        client_body_buffer_size    128k;

        proxy_connect_timeout      150;
        proxy_send_timeout         150;
        proxy_read_timeout         150;

        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
    }
}

EOL

# Get nginx ready.
ln -s /etc/nginx/sites-available/projecto /etc/nginx/sites-enabled/projecto
service nginx restart

# shortcuts
echo "cd /projecto" >> /home/vagrant/.bashrc
echo "alias t='cd /projecto; python -m unittest discover'" >> /home/vagrant/.bashrc
echo "alias s='cd /projecto; python server.py'" >> /home/vagrant/.bashrc

# run the unittests!
echo "All setup complete! Now running teh tests!"
cd /projecto
python -m unittest discover
if [ $? -eq 0 ]; then
    echo "Boom! all tests passed :D"
else
    echo "Uhoh. Something went wrong :("
fi

# make installed flag
touch /home/vagrant/installed
echo "Setup complete. Do 'vagrant ssh' and start playing!"
echo "'s' starts the server"
echo "'t' does the unittests"