# VM 1: lamp-dev (built by hand, Task 2)

This is the **hand-built** learning VM. Vagrant does **not** manage it.
For the Vagrant VM, see `vagrant-vm.md`.
VMware creation settings are in `VMware-VM-creation-settings.md`.

| | |
|---|---|
| Host | `lamp-dev` (Debian 13, VMware Workstation, NAT) |
| Login | My own user, VMware console or SSH from Windows (Git Bash): `ssh <my-user>@192.168.182.128` |
| Address | `http://192.168.182.128` (check with `ip -br a`; may change) |
| Built | 2026-10-06 |
| Verified | 2026-10-11, re-checked 2026-10-27 |
| Snapshots | 1. Apache only  2. `Task 2 - Working LAMP - 2026-10-06` |

## How it was built (by hand, over SSH)

```bash
sudo apt update
sudo apt install apache2                                   # tested, then snapshot
sudo apt install php-cli libapache2-mod-php php-mysql
sudo systemctl restart apache2
sudo apt install mariadb-server
```

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
| PHP | mod_php (runs inside Apache) | n/a | `/etc/php/8.4/apache2/php.ini` (CLI: `/etc/php/8.4/cli/`) | Apache error log |
| MariaDB | mariadb | 127.0.0.1:3306 | `/etc/mysql/mariadb.conf.d/` | `journalctl -u mariadb` |

Paths are Debian defaults. Confirm them on the VM with `php --ini` and
the relevant service checks.

## Checks passed

- [x] apache2 and mariadb are active and enabled at boot
- [x] `sudo apache2ctl configtest` returns Syntax OK
- [x] Apache listens on port 80
- [x] MariaDB is bound to 127.0.0.1:3306 only
- [x] PHP has mysqli, PDO and pdo_mysql
- [x] PHP page served by Apache (tested from the browser)
- [x] MariaDB users: mariadb.sys, mysql, root (all localhost, no `%` hosts)
- [x] `curl -I http://localhost` returns 200 (2026-10-06)

## Checks pending

- [ ] `php --ini` (confirm config file path)
- [ ] `apache2ctl -M` (mod_php or php-fpm, rewrite enabled)
- [ ] `ls /var/www/html` and grep for phpinfo (no public phpinfo page)
- [ ] Remove `php-check.php` again. It was removed on 2026-10-11, which is why
      it returned 404 on 2026-10-27; it was recreated that day for a test.
- [ ] No app uses the MariaDB root account
- [ ] New VM snapshot after the cleanup

## Known warning

`AH00558: Apache could not determine its fully qualified domain name and
used 127.0.1.1.` This is not an error. To silence it later, create
`/etc/apache2/conf-available/servername.conf` containing `ServerName lamp-dev`,
then run `sudo a2enconf servername` and `sudo systemctl reload apache2`. This
is also a good Salt-managed file.

## Gotchas

- `apache2ctl` lives in `/usr/sbin`. Use `sudo apache2ctl` or the full path.
- In `ss` output, the number after `LISTEN 0` is the queue length, not the port.
  Read the **Local Address:Port** column.
- `php -v` tests command-line PHP only. The browser test proves Apache
  executes PHP.
- HTTP 404 = Apache works but the file is missing. 500 = PHP or the app
  crashed. No response = Apache is down or the port is blocked.

## Layers and request flow

- Debian: OS, apt, systemd
- Apache: listens for HTTP and picks the site
- PHP: runs the application code
- MariaDB: stores data

```text
Browser -> Apache (port 80) -> PHP runs code
        -> MariaDB (localhost:3306, only when the app needs data)
```
