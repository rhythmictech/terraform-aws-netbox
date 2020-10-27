#!/bin/bash

exec > >(tee /var/log/user-data.log  2>/dev/console) 2>&1

git clone https://github.com/aws/efs-utils /usr/src/efs-utils
cd /usr/src/efs-utils
./build-deb.sh
apt install -y /usr/src/efs-utils/build/amazon-efs-utils-*.deb

mkdir -p ${mount_point}
mount -t efs ${export}:/ ${mount_point}
echo "${export}:/ ${mount_point} efs default,_netdev,nofail 0 0" >> /etc/fstab

mkdir -p /opt/netbox/current/netbox/media/{devicetype-images,image-attachments}

NETBOX_SECRET=`aws --region us-east-1 secretsmanager get-secret-value --secret-id ${netbox_secret} --query SecretString --output text`
NETBOX_DB_PASSWORD=`aws --region us-east-1 secretsmanager get-secret-value --secret-id ${db_password_secret_arn} --query SecretString --output text`

cat <<END > /opt/netbox/current/netbox/netbox/configuration.py
# Need to set this to '*' or the ELB healthcheck will fail
ALLOWED_HOSTS = ['*']

# PostgreSQL database configuration.
DATABASE = {
    'NAME':             'netbox',
    'USER':             '${db_username}',
    'PASSWORD':         '$NETBOX_DB_PASSWORD',
    'HOST':             '${db_hostname}',
    'PORT':             '',
}

SECRET_KEY = '$NETBOX_SECRET'
LOGIN_REQUIRED = False
PREFER_IPV4 = True
ENFORCE_GLOBAL_UNIQUE = False

REDIS = {
    'tasks': {
        'HOST': 'localhost',
        'PORT': 6379,
        'PASSWORD': '',
        'DATABASE': 0,
        'DEFAULT_TIMEOUT': 300,
        'SSL': False,
    },
    'caching': {
        'HOST': 'localhost',
        'PORT': 6379,
        'PASSWORD': '',
        'DATABASE': 1,
        'DEFAULT_TIMEOUT': 300,
        'SSL': False,
    }
}

END

/bin/systemctl start redis
/bin/systemctl start netbox
/bin/systemctl start netbox-rq
/bin/systemctl start nginx

su - netbox
source /opt/netbox/venv/bin/activate
/opt/netbox/current/netbox/manage.py migrate
/opt/netbox/current/netbox/manage.py remove_stale_contenttypes --no-input
/opt/netbox/current/netbox/manage.py clearsessions
