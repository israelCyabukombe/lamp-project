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
- **Exception to "teach, don't do":** always keep the **Resume here** section (and any facts in this file that a step changed) up to date yourself, without asking, whenever a step is finished or we stop.

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
- No shell provisioner any more (removed Nov 9, 2026, on branch `feature/salt-mariadb`). Apache, PHP and MariaDB all come from Salt.
- Salt states in `salt/roots/` (synced to `/srv/salt`): `top.sls` (`'*'`: `apache`, `php`, `mariadb`), `apache/init.sls` (+ `devprofile-Iz.conf`), `php/init.sls`, `mariadb/init.sls`.
- Salt provisioner (`web.vm.provision :salt`, runs after shell): `masterless = true`, `minion_config = "salt/minion"`, `run_highstate = true`. Vagrant bootstraps the latest Salt: **3008.5 (Argon)**, Python 3.14, in `/opt/saltstack/salt/`.
- Provisioners only run on first create, or with `--provision`. Order is outside-in: `config.vm` provisioners before `web.vm` ones, regardless of file position.
- Done by hand, NOT yet in provisioning: create database `devprofile` and user `devprofile`@`localhost`, `php artisan migrate`.
- `vendor/` (Composer) and `public/build` (Vite) are built on Windows and reach the VM via the synced folder. The VM has no Composer or `unzip` yet.
- Laravel `.env`: `DB_CONNECTION=mysql`, `DB_HOST=127.0.0.1`, `APP_URL=http://localhost:8080`.
- Verified working on Oct 27, 2026. Rebuilt as `web` on Nov 1, 2026 (`vagrant up web` and `vagrant ssh` work, hostname `web`, PHP 8.4.27); the database is NOT recreated yet, so Laravel shows a DB error.
- I use Git Bash: paths look like `/c/Users/israe/source/repos/Lamp-project`, not `C:\...`.

## Next steps (in order)
**Resume here:** Step 3 (Salt). `apache` ✔ (Nov 7) and `php` ✔ (Nov 9, 2026) states done, verified on a fresh VM, merged to `master` (commit `b05a444`). Fresh-VM test: shell installs only MariaDB, highstate passes 7/7, second run 0 changes, `curl -I http://localhost:8080` gives Laravel's 500 (`Apache/2.4.69`) because there's no DB yet.
- **In progress: `mariadb` state** on branch `feature/salt-mariadb`. `salt/roots/mariadb/init.sls` written (`mariadb-package` `pkg.installed` name `mariadb-server`; `mariadb-service` `service.running` name `mariadb`, `enable: True`, `require: - pkg: mariadb-package`; no `include`, so it can move to a `db` VM later) and added to `top.sls`. Tested on the running VM Nov 9: 9/9 passed, 0 changes.
  - Shell provisioner **removed entirely** from the Vagrantfile (Salt's first `pkg` state refreshes the package list once per run, so `apt-get update` isn't needed). Salt is now the only provisioner.
  - Fresh-VM test passed Nov 9 (Salt only): one `Running provisioner: salt...`, no shell output; highstate 9/9, second run 0 changes; MariaDB `enabled` + `active (running)`; curl gives 500.
  - **Next: Step 26**, finish the commit. Commit `285b4b1` "Add mariadb install and config to salt" (already amended once, not pushed) has the `-pkg:` typo version of `mariadb/init.sls`. Still uncommitted: the `- pkg:` fix, the Vagrantfile shell removal, `CLAUDE.md`. Plan: switch `mariadb/init.sls` to LF, `git add` those 3, `git commit --amend --no-edit`, then merge to `master`. After that: the app state (DB + user, password in pillar), or optionally `salt.verbose = true` first.
  - New files created in VS Code start as CRLF even with `.gitattributes` (it only applies when Git writes files). Check with `cat -A` (`^M$` = CRLF). Optional later: VS Code `"files.eol": "\n"`.
  - Editing `top.sls`/`init.sls` is not a Salt "change"; changes are only what happens on the VM.
  - `vagrant provision` = rerun provisioners (highstate) on the running VM, no reboot, skips the Salt bootstrap. Plain `vagrant reload` reboots but does NOT provision. Changed Salt files → provision; changed Vagrantfile settings → reload. Silent on success, so use `salt-call` in the VM to see changes.
  - On Windows an open `vagrant ssh` session holds the machine lock ("another process is already executing an action"): `exit` the VM before `vagrant destroy/up/halt`.
- Database/user creation comes later in the app state (DB password in pillar).
- `php` state: `include: - apache`; `php-packages` (`pkg.installed`, `pkgs:` list of the 6 packages) with `require: - pkg: apache-package` and `watch_in: - service: apache-service`. `watch_in` = `watch` written from the causing side: keeps `apache` independent (php → apache only) and makes `apache-service` run after PHP and reload when PHP packages change (on a fresh VM; Debian's postinst also restarts Apache, but Salt shouldn't rely on that). On an existing VM: "already installed", no change, no reload.
- `state.apply` (no name) = `state.highstate`; `state.apply php` = `state.sls php`. `--local` = masterless (read `/srv/salt`, no master); at work there's a master, so no `--local`.
- Salt compares the machine to the state on every run (no memory of last run): a file Salt previously copied with CRLF changes again once the source is LF.
- Salt 3008 gotcha: `apache_module` / `apache_site` states fail ("`__virtual__` returned False: apache module could not be loaded") because 3008 no longer ships `deb_apache.py` (the `a2enmod`/`a2ensite` functions moved to a Salt extension). Fix used: `cmd.run` with `a2enmod`/`a2ensite`/`a2dissite`, made idempotent with `creates:` (symlink in `mods-enabled`/`sites-enabled`) and `onlyif: test -e ...`. `apache-service` watches them as `cmd: <ID>`. Work may run an older Salt where `apache_module` still works.
- Line endings: CRLF makes `file.managed` show every line changed (and triggers reloads). Cause: Git for Windows sets `core.autocrlf=true` (in `C:/Program Files/Git/etc/gitconfig`), so branch switches/merges rewrite files as CRLF. Fixed Nov 9 with `.gitattributes`: `* text=auto eol=lf`. Files already on disk only pick it up after `rm <files>` + `git checkout -- <files>` (plain checkout skips "unchanged" files). Check with `git ls-files --eol salt/` (want `w/lf`).
- Vagrant only prints Salt's output when a state fails (optional later: `salt.verbose = true`). Port 8080 exists only on the laptop; inside the VM use `curl -I http://localhost` (port 80).
- If `vagrant destroy` is interrupted (Ctrl+C) and later commands say "another process is already executing an action", kill stuck Ruby: `tasklist | grep -i ruby`, then `taskkill //F //IM ruby.exe` (double slashes in Git Bash). Never kill `vagrant-vmware-utility`.
- Later idea (not now): `libapache2-mod-php` is really an Apache module; if a PHP-only VM (e.g. `queue`) is added, move it to the `apache` state so `php` = CLI + extensions only.
- If `vagrant up` says port 8080 is in use: check the owner first with `netstat -ano | grep :8080` then `tasklist //FI "PID eq <pid>"`. If it's `vmnat.exe` (happened again Nov 9), delete the stale 8080/2222 forwards in Virtual Network Editor → Change Settings → VMnet8 → NAT Settings. Always stop the VM with `vagrant halt`.

1. **Finish the rename and recreate the database.**
   - Rename confirmed (hostname `web`, PHP 8.4.27, VMware `web (vagrant)`). Left: commit the Vagrantfile.
   - In `sudo mariadb`: create database `devprofile` (utf8mb4) and user `devprofile`@`localhost` with the `.env` password, grant on `devprofile.*`. Check the login works, then `php artisan migrate`.
2. **Finish provisioning.** Skipped, database moves into the Salt app state.
3. **Salt (keep it small).** Masterless Salt on this VM. Masterless setup + `apache`, `php` and `mariadb` states done (shell provisioner gone); shell lines are removed state by state:
   - `salt/minion` with `file_client: local`, `salt/roots/top.sls`, and `salt/pillar/` synced to `/srv/salt` and `/srv/pillar` (pillar not added yet).
   - Done: `web.vm.provision :salt` block (`masterless = true`, `run_highstate = true`).
   - Write states one at a time (apache ✔ → php ✔ → mariadb ✔ → app, DB password in pillar), removing the matching shell lines as each works.
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
