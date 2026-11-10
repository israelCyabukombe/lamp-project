include:
  - apache

php-packages:
  pkg.installed:
    - pkgs:
      - php-cli
      - libapache2-mod-php
      - php-mysql
      - php-mbstring
      - php-xml
      - php-curl
    - require:
      - pkg: apache-package
    - watch_in:
        - service: apache-service
