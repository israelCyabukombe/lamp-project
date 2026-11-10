include:
  - mariadb

devprofile-database:
  cmd.run:
    - name: mariadb -e "CREATE DATABASE IF NOT EXISTS {{ pillar['database']['name'] }} CHARACTER SET utf8mb4"
    - unless: mariadb -e "SHOW DATABASES" | grep -qx {{ pillar['database']['name'] }}
    - require:
      - service: mariadb-service

devprofile-user:
  cmd.run:
    - name: mariadb -e "CREATE USER IF NOT EXISTS '{{ pillar['database']['user'] }}'@'localhost' IDENTIFIED BY '$DBPASS'; GRANT ALL ON {{ pillar['database']['name'] }}.* TO '{{ pillar['database']['user'] }}'@'localhost'"
    - env:
      - DBPASS: '{{ pillar['database']['password'] }}'
    - unless: mariadb -N -e "SELECT 1 FROM mysql.user WHERE user='{{ pillar['database']['user'] }}' AND host='localhost'" | grep -qx 1
    - require:
      - cmd: devprofile-database