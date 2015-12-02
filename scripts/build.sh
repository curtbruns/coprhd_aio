#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"
  case $key in
    -b|--build)
      build="$2"
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
  shift
done

if [ "$build" = true ] || [ ! -e /vagrant/*.rpm ]; then
  # build CoprHD
  cd /tmp
  git clone https://github.com/CoprHD/coprhd-controller.git
  cd coprhd-controller
  # Change to Release 2.4
  git checkout -b release-2.4-coprhd origin/release-2.4-coprhd
  # Patch Nginx-IPv4.conf
  cd /tmp/coprhd-controller/etc/nginx
  # Create patch file
  cat > /home/vagrant/patch_nginx_ipv4.txt << EOF1
diff --git a/etc/nginx/nginx-IPv4-template.conf b/etc/nginx/nginx-IPv4-template.conf
index 9c8a803..9890726 100644
--- a/etc/nginx/nginx-IPv4-template.conf
+++ b/etc/nginx/nginx-IPv4-template.conf
@@ -115,6 +115,34 @@ http {
         include locations.conf;
         include api-error.conf;
     }
+       server {
+        listen       [::]:8776 ipv6only=on;
+        listen       8776;
+        server_name  localhost;

+        ssl on;
+        ssl_protocols        TLSv1;
+        ssl_ciphers          AES:!ADH;
+        ssl_certificate /opt/storageos/conf/storageos.crt;
+        ssl_certificate_key /opt/storageos/conf/storageos.key;
+        ssl_session_timeout 5m;
+        client_max_body_size 1024M;
+        proxy_redirect             off;
+        proxy_buffering            off;
+        proxy_buffer_size          32k;
+        proxy_buffers           16 32k;
+        proxy_busy_buffers_size   256k;
+        proxy_read_timeout         60m;
+        proxy_set_header  Host               \$host:\$server_port;
+        proxy_set_header  X-Real-IP          \$remote_addr;
+        proxy_set_header  X-Forwarded-Host   \$host;
+        proxy_set_header  X-Forwarded-For    \$proxy_add_x_forwarded_for;
+        proxy_set_header  X-Forwarded-Proto  https;
+        proxy_set_header  X-Forwarded-Ssl    on;
+        proxy_set_header  X-Forwarded-Port   8776;
+        proxy_pass_header Authorization;
+        include locations.conf;
+        include api-error.conf;
+    }
     @nignx_vasasvc2@
 }
EOF1
  patch -l -p3 -R < /home/vagrant/patch_nginx_ipv4.txt
  cd /tmp/coprhd-controller
  make clobber BUILD_TYPE=oss rpm
  #rm -rf /vagrant/*.rpm
  cp -a /tmp/coprhd-controller/build/RPMS/x86_64/storageos-*.x86_64.rpm /vagrant
fi
