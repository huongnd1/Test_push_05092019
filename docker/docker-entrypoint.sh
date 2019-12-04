#!/bin/bash

service ssh start

yq w -i /app/conf/application.yml server.port 8080 \
	&& yq w -i /app/conf/application.yml common.start-time "$(date +"%d/%m/%Y-%H:%M:%S")" \
	&& yq w -i /app/conf/application.yml frontend.dev-mode false \
	&& yq w -i /app/conf/application.yml spring.datasource.url "${DB_URL}" \
	&& yq w -i /app/conf/application.yml spring.datasource.username "${DB_USER}" \
	&& yq w -i /app/conf/application.yml spring.datasource.password "${DB_PASS}" \
	&& yq w -i /app/conf/application.yml spring.redis.database "${REDIS_DATABASE}" \
	&& yq w -i /app/conf/application.yml spring.redis.host "${REDIS_HOST}" \
	&& yq w -i /app/conf/application.yml storage.type azure \
	&& yq w -i /app/conf/application.yml storage.azure.account-name "${ACR_ACCOUNT_NAME}" \
	&& yq w -i /app/conf/application.yml storage.azure.account-key "${ACR_ACCOUNT_KEY}" \
	&& yq w -i /app/conf/application.yml storage.azure.container-name "${ACR_CONTAINER_NAME}" \
	&& yq w -i /app/conf/application.yml sms.type infobip \
	&& yq w -i /app/conf/application.yml sms.dev-mode false \
	&& yq w -i /app/conf/application.yml sms.infobip.username "${INFOBIP_USERNAME}" \
	&& yq w -i /app/conf/application.yml sms.infobip.password "${INFOBIP_PASSWORD}" \
	&& yq w -i /app/conf/application.yml sms.infobip.from "${INFOBIP_FROM}"

if [ -z "${REDIS_PASS}" ]
then
      echo "DO NOTHING"
else
      yq w -i /app/conf/application.yml spring.redis.password "${REDIS_PASS}"
fi

cat /app/conf/application.yml

/app/run.sh