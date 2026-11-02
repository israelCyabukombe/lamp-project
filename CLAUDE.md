# Project context: LAMP learning environment (devprofile-Iz)

## Who I am
- I'm a beginner learning LAMP system design with Vagrant, then Salt, then Ansible.
- At work I've used Salt (`sudo salt-call state.highstate`) on a 5-VM setup: web (PHP), db (MariaDB), queue (RabbitMQ), cache, elastic, monitor.

## How to work with me (IMPORTANT: I'm here to LEARN, not to get it done fast)
- **Teach, don't do.** Don't edit my Vagrantfile, Salt states, or app files, and don't run commands yourself, unless I explicitly ask you to. Show me what to type and let me do it.
- **One step at a time.** Give me one small step (1–3 commands or a few lines of config), then stop and wait for my output before giving the next step.
- **Explain every command.** Say in plain words what it does and why we need it. Define new terms the first time you use them.
- **Keep it simple.** Use the most basic way that works. No extra features, tools, or "best practice" add-ons I didn't ask for. If there's a more advanced way, mention it in one line for later, but don't use it.
- **Don't skip ahead** to later roadmap steps or do several steps at once.
- **Check before moving on.** After each step, tell me what output to expect and how to verify it worked.
- **Ask me to predict** sometimes ("what do you think this will do?") before showing the answer.
- If I ask "why", explain the concept before giving more commands.
- Never ask me to commit `.env` or secrets.

## Detailed notes (read these when you need specifics)
- `notes/lamp-dev-manual-vm.md`: the hand-built VM (versions, config paths, checks, gotchas)
- `notes/vagrant-vm.md`: the Vagrant VM (Vagrantfile, provisioning, next steps, Salt plan)
- `notes/VMware-VM-creation-settings.md`: VMware settings used for `lamp-dev`
- Folder layout: `C:/Users/myusername/source/repos/lamp-project` (Vagrantfile, notes) and its sibling `devprofile-Iz` (the Laravel app repo)

## Goal
Rebuild my devprofile site (currently .NET + React/TypeScript at icyabu.com) as a Laravel app on LAMP, in an environment that can be rebuilt from code: Vagrant now, Salt next, Ansible later (work is moving to Ansible).

## Two VMs. Don't confuse them.
| | `lamp-dev` | `web` (Vagrant VM, this folder) |
|---|---|---|
| Built | By hand in VMware Workstation (learning only) | `vagrant up` from this Vagrantfile |
| Login | My own user | `vagrant ssh` |
| Hostname | `lamp-dev` | `web` |
| Vagrant name | n/a | `web` (renamed from `default` 2026-11-01) |
| VMware display name | n/a | `web (vagrant)` |
| URL | `http://192.168.182.128` | `http://localhost:8080` (forwards to guest port 80) |
| Laravel app | No | Yes |

Both run Debian 13: Apache 2.4.68, PHP 8.4, MariaDB 11.8 (bound to 127.0.0.1:3306).

## Vagrant VM details
- Provider `vmware_desktop`, box `bento/debian-13` version `202510.26.0` (top-level `config`). Machine settings live in `config.vm.define "web"`: hostname, synced folder, forwarded port guest 80 → host 127.0.0.1:8080, VMware `displayName`.
- `devprofile-Iz` is a synced folder from the laptop, mounted at `/var/www/devprofile-Iz`. The code and `.env` survive `vagrant destroy`; MariaDB data does not.
- Inline shell provisioner (first `vagrant up` only): installs `apache2 mariadb-server php-cli libapache2-mod-php php-mysql php-mbstring php-xml php-curl`, runs `a2enmod rewrite`, writes an Apache site `devprofile-Iz.conf` (DocumentRoot `/var/www/devprofile-Iz/public`, `AllowOverride All`), disables `000-default`, enables the services.
- Done by hand, NOT yet in provisioning: create database `devprofile` and user `devprofile`@`localhost`, `php artisan migrate`.
- `vendor/` (Composer) and `public/build` (Vite) are built on Windows and reach the VM via the synced folder. The VM has no Composer or `unzip` yet.
- Laravel `.env`: `DB_CONNECTION=mysql`, `DB_HOST=127.0.0.1`, `APP_URL=http://localhost:8080`.
- Verified working on Oct 27, 2026. Rebuilt as `web` on Nov 1, 2026 (`vagrant up web` and `vagrant ssh` work, hostname `web`, PHP 8.4.27); the database is NOT recreated yet, so Laravel shows a DB error.
- I use Git Bash: paths look like `/c/Users/israe/source/repos/Lamp-project`, not `C:\...`.

## Next steps (in order)
**Resume here:** VM is halted after the rename. Start with `vagrant up web`, then pick up at step 1. Exact commands are in `notes/vagrant-vm.md` → Next steps.
- If `vagrant up` says port 8080 is in use and the owner is `vmnat`, delete the stale 8080/2222 forwards in Virtual Network Editor → VMnet8 → NAT Settings. Always stop the VM with `vagrant halt`.

1. **Finish the rename and recreate the database.**
   - Rename confirmed (hostname `web`, PHP 8.4.27, VMware `web (vagrant)`). Left: commit the Vagrantfile.
   - In `sudo mariadb`: create database `devprofile` (utf8mb4) and user `devprofile`@`localhost` with the `.env` password, grant on `devprofile.*`. Check the login works, then `php artisan migrate`.
2. **Finish provisioning.** Add the database/user creation and migrations so that `vagrant destroy` followed by `vagrant up` gives a working app with no manual steps.
3. **Salt (keep it small).** Masterless Salt on this VM:
   - `salt/minion` with `file_client: local`, `salt/roots/top.sls`, and `salt/pillar/` synced to `/srv/salt` and `/srv/pillar`.
   - Add a `config.vm.provision :salt` block (`masterless = true`, `run_highstate = true`).
   - Write states one at a time (apache → php → mariadb → app, DB password in pillar), removing the matching shell lines as each works.
   - Test idempotency: `sudo salt-call --local state.apply` twice, and the second run should show 0 changes.
4. **Ansible.** Rebuild the same thing with roles and variables.
5. **More VMs.** Split out a `db` VM, then `queue`, `cache`, `elastic` (same role naming as `web`).
6. **Build devprofile features.** Then deploy to production with HTTPS.
7. **Polish the documentation (at the end).** The current notes are a learning log; leave them in that style until then. Afterwards, write separate professional docs (a rebuild guide, not a tutorial). Gaps to cover are listed in `notes/vagrant-vm.md` → "Documentation polish".

## Repo / git notes (devprofile-Iz app repo, not this folder)
- Branch `master`. Keep history linear (fast-forward / rebase and merge).
- Open items:
  - GitHub Actions CI needs a MariaDB service container; confirm it passes.
  - Confirm the workflow triggers on `master`.
  - Delete `.env.bak`.

## Handy checks (inside the VM)
`hostname; sudo apache2ctl -v; php -v; mariadb --version; systemctl status apache2 mariadb --no-pager; sudo ss -lntp; curl -I http://localhost; cd /var/www/devprofile-Iz && php artisan migrate:status`
