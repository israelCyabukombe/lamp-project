# Task 2 Notes: Apache, PHP, MariaDB on lamp-dev

Verified: 2026-10-11
Host: lamp-dev (Debian 13, VMware Workstation)
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
| PHP | mod_php (runs inside Apache) | n/a | `/etc/php/8.4/apache2/php.ini` (CLI: `/etc/php/8.4/cli/`) | Apache error log |
| MariaDB | mariadb | 127.0.0.1:3306 | `/etc/mysql/mariadb.conf.d/` | `journalctl -u mariadb` |

Paths are Debian defaults. Confirm them on the VM with `php --ini` and
the relevant service checks.

## What is Vagrant?

Vagrant is a tool for building and managing virtual machine environments
from a single configuration file called the `Vagrantfile`. The file
describes the machine you need (OS box, networking, shared folders) and
how to set it up. Anyone can check out the repo, run `vagrant up`, and
get the same VM.

### Where it fits in the LAMP stack

Vagrant is not part of the stack. It builds the machine the stack runs on.

- Vagrant + VMware: creates the Debian VM and shares the code folder.
- Apache, PHP, MariaDB: the stack itself, installed inside the VM.
- Laravel (`devprofile-Iz`): the application, shared in from Windows.

### How it differs from Salt (planned)

| | Vagrant | Salt |
|---|---|---|
| Job | Creates and manages the VM | Configures what is inside a machine |
| Describes | Box, ports, shared folders | Packages, services, file contents |
| Config file | `Vagrantfile` (Ruby) | State files (`.sls`, YAML) |
| Scope | Local dev VMs | Any number of machines, dev to production |

They work together. Vagrant has a built-in Salt provisioner, so Vagrant
creates the VM and Salt configures it. The shell script below is the
interim step until the Salt states exist.

## Vagrant setup

The Vagrant project is in `lamp-project`. The application repository,
`devprofile-Iz`, is its sibling directory.

```sh
pwd -W
# C:/Users/myusername/source/repos/lamp-project
cd ~/source/repos/lamp-project
vagrant init
```

In the generated `Vagrantfile`, replace `config.vm.box = "base"` with the
pinned Debian 13 box:

```ruby
config.vm.box = "bento/debian-13"
config.vm.box_version = "202510.26.0"
```

Vagrant shares the project folder with the VM by default. Add a second
shared folder for the application, plus a forwarded port:

```ruby
config.vm.synced_folder "../devprofile-Iz", "/var/www/devprofile-Iz"
config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
```

Start the VM, then apply Vagrantfile changes later with a reload:

```sh
vagrant up --provider=vmware_desktop
vagrant reload --provision
```

The guest identifies itself as `Debian GNU/Linux 13 (trixie)` in
`/etc/os-release`.

## Interim shell provisioning

- Installs `apache2`, `mariadb-server`, `php-cli`, `libapache2-mod-php`,
  `php-mysql`, `php-mbstring`, `php-xml`, and `php-curl`.
- Enables `mod_rewrite`. The virtual host serves `devprofile-Iz/public`.
- The virtual host is written with `printf`. A heredoc broke because
  Vagrant keeps the indentation, so bash never found the closing `EOF`.

## App database

- Laravel uses MariaDB through `DB_CONNECTION=mysql` in `.env`. The file
  lives in `devprofile-Iz` and is not committed.
- Laravel defaults to SQLite. The VM has no SQLite driver, which caused
  "could not find driver". Switching to MariaDB fixed the cause.

## Checks passed

- [x] apache2 and mariadb are active and enabled at boot
- [x] `sudo apache2ctl configtest` returns Syntax OK
- [x] Apache listens on port 80
- [x] MariaDB is bound to 127.0.0.1:3306 only
- [x] PHP has mysqli, PDO and pdo_mysql
- [x] PHP page served by Apache (tested from the browser)
- [x] MariaDB users: mariadb.sys, mysql, root (all localhost, no `%` hosts)
- [x] `php-check.php` removed from `/var/www/html`

## Checks pending

- [ ] `php --ini` (confirm config file path)
- [ ] `apache2ctl -M` (mod_php or php-fpm, rewrite enabled)
- [ ] `ls /var/www/html` and grep for phpinfo (no public phpinfo page)
- [ ] `curl -I http://localhost`
- [ ] No app uses the MariaDB root account
- [ ] VM snapshot taken

## Known warning

`AH00558: Apache could not determine its fully qualified domain name and
used 127.0.1.1.` This is not an error. Set `ServerName` later
(`a2enconf servername`), which is also a good Salt-managed file.

## Gotchas

- `apache2ctl` lives in `/usr/sbin`. Use `sudo apache2ctl` or the full path.
- In `ss` output, the number after `LISTEN 0` is the queue length, not the port.
- `php -v` tests command-line PHP only. The browser test proves Apache
  executes PHP.

## Layers and request flow

- Debian: OS, apt, systemd
- Apache: listens for HTTP and picks the site
- PHP: runs the application code
- MariaDB: stores data
- Laravel: the application that uses all three

```text
Browser -> Apache (port 80) -> PHP runs code
        -> MariaDB (localhost:3306, only when the app needs data)
```

## Notes for Salt later

- Packages: apache2, php, libapache2-mod-php (or php-fpm), php-mysql,
  php-mbstring, php-xml, php-curl, mariadb-server
- Services to keep running and enabled: apache2, mariadb
- Files to manage: vhost, ServerName conf, php.ini overrides, MariaDB
  bind-address
- Apache modules: rewrite (Laravel needs it)
- Next: replace the shell provisioner with masterless Salt and match the
  role layout from the work Vagrantfile
