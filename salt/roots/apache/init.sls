apache-package:
  pkg.installed:
    - name: apache2

apache-rewrite-module:
  cmd.run:
    - name: a2enmod rewrite
    - creates: /etc/apache2/mods-enabled/rewrite.load
    - require:
      - pkg: apache-package

apache-site-config:
  file.managed:
    - name: /etc/apache2/sites-available/devprofile-Iz.conf
    - source: salt://apache/devprofile-Iz.conf
    - require:
      - pkg: apache-package

apache-site-enabled:
  cmd.run:
    - name: a2ensite devprofile-Iz
    - creates: /etc/apache2/sites-enabled/devprofile-Iz.conf
    - require:
      - file: apache-site-config

apache-default-site-disabled:
  cmd.run:
    - name: a2dissite 000-default
    - onlyif: test -e /etc/apache2/sites-enabled/000-default.conf
    - require:
      - pkg: apache-package

apache-service:
  service.running:
    - name: apache2
    - enable: True
    - reload: True
    - watch: 
      - cmd: apache-rewrite-module
      - file: apache-site-config
      - cmd: apache-site-enabled
      - cmd: apache-default-site-disabled