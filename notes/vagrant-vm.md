# VM 2: Vagrant VM (repeatable build)

This VM is built **by Vagrant** from `lamp-project/Vagrantfile`. It is
separate from the hand-built `lamp-dev` (see `lamp-dev-manual-vm.md`).

| | |
|---|---|
| Vagrant machine name | `web` (renamed from `default` on 2026-11-01) |
| Hostname | `web` (set by `web.vm.hostname`) |
| VMware display name | `web (vagrant)` |
| Login | `vagrant ssh web` (user `vagrant`) |
| Box | `bento/debian-13`, version `202510.26.0`, provider `vmware_desktop` |
| OS | `Debian GNU/Linux 13 (trixie)` |
| App URL | `http://localhost:8080` (host 127.0.0.1:8080 forwards to guest :80) |
| Verified | 2026-10-27: versions, services, ports, synced folder, Apache → Laravel, Laravel → MariaDB. 2026-11-01: rebuilt as `web`; `vagrant up web` and `vagrant ssh` work, hostname is `web`, PHP 8.4.27, VMware shows `web (vagrant)`. Database not recreated yet, so Laravel shows a DB error. |

## What is Vagrant?

Vagrant builds and manages virtual machines from a single configuration
file, the `Vagrantfile`. The file describes the machine (OS box,
networking, shared folders) and how to set it up. Anyone can check out
the repo, run `vagrant up`, and get the same VM.

Vagrant is not part of the stack. It builds the machine the stack runs on.

- Vagrant + VMware: creates the Debian VM and shares the code folder.
- Apache, PHP, MariaDB: the stack itself, installed inside the VM.
- Laravel (`devprofile-Iz`): the application, shared in from Windows.

### Vagrant vs Salt (planned)

| | Vagrant | Salt |
|---|---|---|
| Job | Creates and manages the VM | Configures what is inside a machine |
| Describes | Box, ports, shared folders | Packages, services, file contents |
| Config file | `Vagrantfile` (Ruby) | State files (`.sls`, YAML) |
| Scope | Local dev VMs | Any number of machines, dev to production |

They work together. Vagrant has a built-in Salt provisioner, so Vagrant
creates the VM and Salt configures it. The shell script is the interim
step until the Salt states exist.

## Folder layout

```text
C:/Users/myusername/source/repos/
├── lamp-project/      Vagrantfile, notes/, (later) salt/
└── devprofile-Iz/     Laravel app (its own git repo), synced into the VM
```

## Vagrantfile settings

Current settings. Box and provisioner are top-level (shared by every
machine); the rest belongs to the `web` machine only:

```ruby
config.vm.box = "bento/debian-13"
config.vm.box_version = "202510.26.0"

config.vm.define "web" do |web|
  web.vm.hostname = "web"
  web.vm.synced_folder "../devprofile-Iz", "/var/www/devprofile-Iz"
  web.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  web.vm.provider "vmware_desktop" do |v|
    v.vmx["displayName"] = "web (vagrant)"
  end
end
```

- `host: 8080` is the laptop side, `guest: 80` is where Apache listens in
  the VM. Changing only `host` changes the URL (and `APP_URL`), not Apache.
- `vagrant status` lists machines **defined in the Vagrantfile**, not the
  last one created. Run it from `lamp-project` (Git Bash path:
  `/c/Users/israe/source/repos/Lamp-project`).

The app folder is synced from Windows, so the code **and `.env`** survive
`vagrant destroy`. The MariaDB data inside the VM does not.

## Interim shell provisioning

This runs on the **first** `vagrant up` only. To run it again, use
`vagrant provision` or `vagrant reload --provision`.

- Installs `apache2`, `mariadb-server`, `php-cli`, `libapache2-mod-php`,
  `php-mysql`, `php-mbstring`, `php-xml`, `php-curl` (non-interactive, `-y`).
- Enables `mod_rewrite` so Laravel's `public/.htaccess` routing works.
- Writes the virtual host `devprofile-Iz.conf` (DocumentRoot
  `devprofile-Iz/public`, `AllowOverride All`), disables `000-default`.
- Enables and starts apache2 and mariadb. `apt-get install` does the
  installing (PHP included); `systemctl enable --now` only sets installed
  services to start on boot and starts them now. On later boots the
  provisioner is skipped and systemd starts the services by itself.
- `000-default.conf` is Debian's sample Apache site ("It works!"), not
  related to Vagrant's old `default` machine name.
- The virtual host is written with `printf`. A heredoc broke because
  Vagrant keeps the indentation, so bash never found the closing `EOF`.

## App database

- Laravel uses MariaDB through `DB_CONNECTION=mysql`, `DB_HOST=127.0.0.1`
  in `.env`. The file lives in `devprofile-Iz` and is not committed.
- Laravel defaults to SQLite. The VM has no SQLite driver, which caused
  "could not find driver". Switching to MariaDB fixed it.
- Database `devprofile`, user `devprofile`@`localhost`.

### Done by hand. Still to add to provisioning

These were done by hand and work today. They are unticked because they are
not in provisioning yet. Without them, `vagrant destroy` + `vagrant up` gives
a working Apache/PHP but Laravel fails with a database error:

- [ ] Create database `devprofile` and user `devprofile`@`localhost`
- [ ] `php artisan migrate`

`vendor/` (Composer) and `public/build` (Vite, `npm run build`) are built
on **Windows** and reach the VM through the synced folder. The VM has no
Composer or `unzip`, so `composer install` inside the VM fails with
"command not found" until provisioning installs them.

## Next steps

**Resume here (2026-11-01):** VM is halted. Start it with `vagrant up web`.

0. **Rename done** (hostname `web`, PHP 8.4.27, VMware `web (vagrant)`).
   Left: commit the Vagrantfile.
1. **Recreate the database by hand** (the rename's destroy wiped it):
   - `vagrant ssh web`, then `sudo mariadb`, then (password = `DB_PASSWORD`
     from `devprofile-Iz/.env`):
     ```sql
     CREATE DATABASE devprofile CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
     CREATE USER 'devprofile'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD';
     GRANT ALL PRIVILEGES ON devprofile.* TO 'devprofile'@'localhost';
     EXIT;
     ```
   - Check: `mariadb -u devprofile -p devprofile -e "SELECT DATABASE();"`
     prints `devprofile`.
   - Then `cd /var/www/devprofile-Iz && php artisan migrate` (the new
     database is empty, so the site still fails until the tables exist).
   - Open question to answer: will `http://localhost:8080` work right after
     the user check, or is something still missing?
2. **Add the database steps to provisioning**, then test a full
   `vagrant destroy` + `vagrant up` with no manual steps.
3. **Replace the shell provisioner with masterless Salt** (see below).
4. **Later: hosting more than one app on `web`.** Right now the provisioner
   disables `000-default` and makes devprofile the only site on port 80. A
   second app needs its own virtual host (`ServerName`), synced folder, and
   database.

## Documentation polish (at the end)

These notes are a learning log on purpose. Once the stack is finished,
write separate, professional docs. Goal: someone (or me, years later)
can rebuild everything from a bare laptop. Gaps found on 2026-11-01:

- **Host tools and versions:** Vagrant, `vagrant-vmware-desktop` plugin,
  Vagrant VMware Utility, VMware Workstation, Git, Composer, Node/npm.
- **Where the code lives:** git remote URLs for `Lamp-project` and
  `devprofile-Iz`.
- **`.env`:** keep `.env.example` complete so the guide is "copy it, set
  `DB_PASSWORD`".
- **Known-working versions:** Debian 13, PHP 8.4.27, Apache 2.4.x,
  MariaDB 11.8. The pinned box may disappear from Vagrant Cloud, and apt
  pulls newer packages over time.
- **Split by purpose:** rebuild guide (only steps true today), concepts and
  lessons, and status/next steps (dated, temporary).
- **Push steps into code first:** every manual step moved into provisioning
  (later Salt/Ansible) is one the docs no longer need to explain.

## Notes for Salt later

- Packages: apache2, php, libapache2-mod-php (or php-fpm), php-mysql,
  php-mbstring, php-xml, php-curl, mariadb-server
- Services to keep running and enabled: apache2, mariadb
- Files to manage: vhost, ServerName conf, php.ini overrides, MariaDB
  bind-address
- Apache modules: rewrite (Laravel needs it)
- App: database + user (password in pillar), migrations
- Setup: `salt/minion` (`file_client: local`), `salt/roots/top.sls`,
  `salt/pillar/`, plus a `config.vm.provision :salt` block
  (`masterless = true`, `run_highstate = true`)
- Write one state at a time (apache → php → mariadb → app) and remove the
  matching shell lines as each state works.
- Idempotency test: `sudo salt-call --local state.apply` twice; the second
  run should report 0 changes.

## Vagrant commands

| Command | What it does |
|---|---|
| `vagrant status` / `vagrant global-status` | This project's VM / all Vagrant VMs |
| `vagrant up` | Boot; create and provision the first time only |
| `vagrant provision` | Run the provisioners again |
| `vagrant reload` | Restart and apply Vagrantfile changes |
| `vagrant ssh` | Log in |
| `vagrant halt` | Clean shutdown |
| `vagrant destroy` | Delete the VM |

With one machine defined, `vagrant up` / `vagrant ssh` without a name
target it. Typing the name (`vagrant up web`) is a good habit for when
there are more VMs. Saving the Vagrantfile is enough; no need to restart
the terminal.

### "Port 8080 is already in use" on `vagrant up`

1. Check `vagrant status`, because the VM may already be running.
2. Check what holds the port: `netstat -ano | findstr :8080` (PowerShell)
   or `netstat -ano | grep :8080` (Git Bash).
3. If the owner is `vmnat` (VMware's NAT service), VMware kept stale port
   forwards from an earlier session in `C:\ProgramData\VMware\vmnetnat.conf`
   (seen 2026-10-27: `8080` and `2222` → `192.168.182.129`). This happens when
   the VM is stopped outside Vagrant. Fix: VMware Workstation → Edit →
   Virtual Network Editor → Change Settings → VMnet8 → NAT Settings, then
   delete the 8080 and 2222 entries.
4. Prevention: always stop the VM with `vagrant halt`, not the VMware GUI.
