# Task 2 Notes: Apache, PHP, MariaDB on lamp-dev

Verified: 2026-10-11  
Host: lamp-dev (Debian, VMware Workstation)  
Snapshot: <name>

## Verified versions

| Software | Version | Check |
|---|---|---|
| Apache | 2.4.68 (Debian), built 2026-06-11 | `sudo apache2ctl -v` |
| PHP | 8.4.26 (cli, NTS), OPcache 8.4.26 | `php -v` |
| MariaDB | 11.8.6, client 15.2 | `mariadb --version` |
| PHP DB modules | mysqli, PDO, pdo_mysql | `php -m` |

## Services and ports

| Software | Service | Port | Config path | Log |
|---|---|---|---|---|
| Apache | apache2 | *:80 | `/etc/apache2/apache2.conf` | `/var/log/apache2/error.log` |
| PHP | runs inside Apache (mode pending) | n/a | pending (`php --ini`) | Apache error log |
| MariaDB | mariadb | 127.0.0.1:3306 | `/etc/mysql/mariadb.conf.d/` | `journalctl -u mariadb` |

Paths are Debian defaults. Confirm them on the VM.

## Checks passed

- [x] apache2 and mariadb are active
- [x] apache2 and mariadb are enabled at boot
- [x] apache2ctl configtest returns Syntax OK
- [x] Apache listens on port 80
- [x] MariaDB is bound to 127.0.0.1:3306 only
- [x] PHP has mysqli, PDO and pdo_mysql
- [x] PHP page served by Apache (tested earlier from the browser)

## Checks pending

- [ ] `php --ini` (config file path)
- [ ] `apache2ctl -M` (mod_php or php-fpm, rewrite enabled?)
- [ ] `ls /var/www/html` and grep phpinfo (no public phpinfo page)
- [ ] `curl -I http://localhost`
- [ ] Account check: no app uses MariaDB root
- [ ] VM snapshot taken

## Known warning

`AH00558: Apache could not determine its fully qualified domain name and
used 127.0.1.1.` This is not an error. Fix later by setting ServerName
(`a2enconf servername`), which is also a good Salt-managed file.

## Gotchas

- `apache2ctl` lives in `/usr/sbin`. Use sudo or the full path.
- In `ss` output, the number after `LISTEN 0` is the queue length,
  not the port.
- `php -v` tests command-line PHP only. The browser test proves Apache
  executes PHP.

## Layers

- Debian: OS, apt, systemd
- Apache: listens for HTTP and picks the site
- PHP: runs the application code
- MariaDB: stores data
- Future app (Laravel): code that uses all three

## Request flow

```text
Browser -> Apache (port 80) -> PHP runs code
        -> MariaDB (localhost:3306, only when the app needs data)
```

## Notes for Salt later

- Packages: apache2, php, libapache2-mod-php (or php-fpm),
  php-mysql, mariadb-server
- Services to keep running and enabled: apache2, mariadb
- Files to manage: vhost, ServerName conf, php.ini overrides,
  MariaDB bind-address
- Apache modules: rewrite (Laravel needs it)

- [x] MariaDB users: mariadb.sys, mysql, root (all localhost, no `%` hosts)
- [x] Apache PHP config: `/etc/php/8.4/apache2/php.ini` (CLI uses `/etc/php/8.4/cli/`)
- [x] `php-check.php` removed from `/var/www/html`
- [ ] VM snapshot taken:
