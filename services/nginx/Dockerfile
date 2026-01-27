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
    sed -i "s/^user  nginx;$/user  nginx ${NGINX_GROUP};/" /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
