# 🔒 Security Best Practices

This document outlines security considerations for your Laravel Production Docker Server.

## 🚨 Before Production Deployment

### 1. Change Default Passwords

**CRITICAL:** The `.env.example` contains placeholder passwords. You MUST change these:

```bash
# Generate strong passwords (use a password manager)
# Recommended: 32+ characters with mixed case, numbers, symbols

MYSQL_ROOT_PASSWORD=your_very_long_and_random_password_here
MYSQL_PASSWORD=another_very_long_and_random_password_here
```

### 2. Enable HTTPS/SSL

This stack currently runs on HTTP only. For production, you MUST add SSL:

**Option 1: Cloudflare Tunnel (Recommended for Homelab)**
- Automatic SSL certificates
- No port forwarding needed
- DDoS protection included

**Option 2: Let's Encrypt with Certbot**
```bash
# Add certbot to docker-compose.yml
# Configure nginx to use SSL certificates
# Enable automatic renewal
```

**Option 3: Reverse Proxy (Traefik/Nginx Proxy Manager)**
- Handles SSL termination
- Automatic certificate renewal
- Multiple services support

### 3. Firewall Configuration

Ensure your server firewall is configured:

```bash
# Allow only necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (if using direct access)
sudo ufw allow 443/tcp   # HTTPS (if using direct access)
sudo ufw enable
```

### 4. Restrict Database Access

By default, MySQL is not exposed to the host network (good!). Keep it that way unless you have a specific need.

If you must expose MySQL, restrict access:
```yaml
# In docker-compose.yml
mysql:
  ports:
    - "127.0.0.1:3306:3306"  # Only localhost can access
```

### 5. Enable Rate Limiting

Uncomment rate limiting in [config/vhosts/default.conf](../config/vhosts/default.conf):

```nginx
# Add to http block (create nginx.conf if needed):
limit_req_zone $binary_remote_addr zone=php_limit:10m rate=10r/s;

# Then uncomment in default.conf:
limit_req zone=php_limit burst=20 nodelay;
```

### 6. Regular Updates

Keep your stack updated:

```bash
# Update Docker images
docker compose pull

# Rebuild with latest security patches
docker compose build --no-cache

# Update Laravel dependencies
docker compose exec php8.4 composer update
```

## 🔐 Security Checklist

- [ ] Changed all default passwords in `.env`
- [ ] Enabled HTTPS/SSL
- [ ] Configured firewall rules
- [ ] Added `.env` to `.gitignore` (already done)
- [ ] Disabled PHP error display in production (already configured)
- [ ] Enabled rate limiting for PHP requests
- [ ] Set up automated backups for MySQL
- [ ] Configured log monitoring
- [ ] Disabled root SSH access on server
- [ ] Set up fail2ban or similar intrusion detection
- [ ] Reviewed Laravel `.env` APP_DEBUG=false
- [ ] Verified file permissions (www-data ownership)

## 🛡️ Built-in Security Features

✅ **Already Configured:**
- Security headers (X-Frame-Options, CSP, etc.)
- PHP version hiding (`expose_php = Off`)
- Server tokens disabled
- Only `index.php` can execute (other PHP files blocked)
- Sensitive files blocked (.env, .git, etc.)
- Session cookie security (httponly, strict mode)
- Resource limits prevent DoS attacks
- Health checks detect compromised containers
- Non-root user in PHP container

## 🚨 Emergency Response

If your server is compromised:

1. **Immediately stop containers:** `docker compose down`
2. **Check logs:** `docker compose logs > incident.log`
3. **Change all passwords**
4. **Review access logs** in `/var/log/nginx/`
5. **Scan for malware** in `./app` directory
6. **Restore from clean backup**
7. **Update all software** before restarting

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Laravel Security Best Practices](https://laravel.com/docs/security)
- [Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Nginx Hardening Guide](https://www.cyberciti.biz/tips/linux-unix-bsd-nginx-webserver-security.html)
