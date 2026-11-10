mariadb-package:
  pkg.installed:
    - name: mariadb-server

mariadb-service:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - pkg: mariadb-package