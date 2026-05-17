# Use official Nginx Alpine image
FROM nginx:alpine

# Get UID/GID from build arguments (default to 1000 if not provided)
ARG UID=1000
ARG GID=1000

# Create nginx user with matching UID/GID
# Handle macOS where GID 20 (staff) already exists
RUN deluser nginx 2>/dev/null || true && \
    if getent group ${GID} > /dev/null 2>&1; then \
        # GID exists, create user with that existing group\
        GROUP_NAME=$(getent group ${GID} | cut -d: -f1) && \
        adduser -D -u ${UID} -G ${GROUP_NAME} nginx; \
    else \
        # GID doesn't exist, create group and user normally\
        addgroup -g ${GID} nginx && \
        adduser -D -u ${UID} -G nginx nginx; \
    fi

# Set proper permissions for Nginx directories
# Use the actual group assigned to nginx user
RUN NGINX_GROUP=$(id -gn nginx) && \
    chown -R nginx:${NGINX_GROUP} /var/cache/nginx && \
    chown -R nginx:${NGINX_GROUP} /var/log/nginx && \
    chown -R nginx:${NGINX_GROUP} /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:${NGINX_GROUP} /var/run/nginx.pid && \
    # Update nginx.conf to use the actual group instead of hardcoded "nginx"\
    sed -i "s/^user  nginx;$/user  nginx ${NGINX_GROUP};/" /etc/nginx/nginx.conf && \
    # Use all available CPU cores
    sed -i 's/worker_processes  1;/worker_processes  auto;/' /etc/nginx/nginx.conf && \
    # Raise open file limit
    sed -i '/worker_processes/a worker_rlimit_nofile 65535;' /etc/nginx/nginx.conf && \
    # Tune event loop for high concurrency
    sed -i 's/worker_connections  1024;/worker_connections  4096;\n    use epoll;\n    multi_accept on;/' /etc/nginx/nginx.conf && \
    # Enable gzip compression globally
    sed -i 's/#gzip  on;/gzip on;\n    gzip_vary on;\n    gzip_proxied any;\n    gzip_comp_level 6;\n    gzip_min_length 1000;\n    gzip_types text\/plain text\/css text\/xml application\/json application\/javascript application\/xml+rss font\/truetype font\/opentype application\/vnd.ms-fontobject image\/svg+xml;/' /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
