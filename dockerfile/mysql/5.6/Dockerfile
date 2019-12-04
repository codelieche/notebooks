FROM percona:5.6.45-centos

USER root
RUN yum update -y && yum install -y wget vim sudo tree net-tools percona-xtrabackup-24 \
    && yum clean all \
    && rm -rf /var/cache/yum
# RUN yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
# RUN yum install percona-xtrabackup-24 -y
RUN echo "changeme" | passwd --stdin root \
    && mkdir /backup && chown mysql:mysql /backup

VOLUME ["/var/lib/mysql", "/var/log/mysql", "/backup"]
# You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD
ENV MYSQL_ROOT_PASSWORD=changeme

COPY ./backup/ /backup/
RUN chown mysql:mysql -R /backup/

USER mysql
RUN cat /backup/my.cnf > /etc/my.cnf
CMD ["/bin/bash", "-c", "/docker-entrypoint.sh mysqld"]