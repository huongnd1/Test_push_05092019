FROM openjdk:8-jre AS final

WORKDIR /app

# ARG FOR BUILD
ARG project_name="mobile-endpoint"
ARG dockerfile_dir="${project_name}/docker/"
ARG build_zip_file="dist/${project_name}/${project_name}.zip"

# SSH FOR AZURE
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
	&& apt-get install -y --no-install-recommends dialog \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd

COPY ${dockerfile_dir}/sshd_config /etc/ssh/

# UPDATE TIMEZONE
ENV TZ=Asia/Bangkok
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# INSTALL YAML EDITOR
COPY ${dockerfile_dir}/yq /usr/bin/yq
RUN chmod +x /usr/bin/yq

# PROPERTIES
ENV DB_URL="jdbc:mysql://hisalon-dev.mysql.database.azure.com:3306/hisalon-dev?useSSL=true&verifyServerCertificate=false&useUnicode=true&character_set_server=utf8mb4"
ENV DB_USER="hisalon@hisalon-dev"
ENV DB_PASS="Mbinno!@#456"
ENV REDIS_DATABASE="1"
ENV REDIS_HOST="127.0.0.1"
ENV ACR_CONTAINER_NAME="hisalon-dev"
ENV ACR_ACCOUNT_NAME="hisalon"
ENV ACR_ACCOUNT_KEY="r6W9/no7xWbKo64Mv50PhhX0rzMj/3y2FMsuMPWdMjQc7WN42q6QDDKJI7nso2emuwUykguhwU4tQsLeZzZCiA=="
ENV INFOBIP_USERNAME="huongtest1"
ENV INFOBIP_PASSWORD="giadinhlaso1aA@"
ENV INFOBIP_FROM="ATI"

COPY ${dockerfile_dir}/docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

# CREATE LOGS FOLDER
RUN mkdir logs && mkdir temp

# UNZIP BUILD
ADD ${build_zip_file} build/build.zip
RUN cd build && unzip build.zip

# MOVE BINARY FILES
RUN mv build/${project_name}/run.sh run.sh \
	&& chmod +x run.sh \
	&& mkdir conf \
	&& mv build/${project_name}/conf/* conf/ \
	&& mkdir bin \
	&& mv build/${project_name}/bin/* bin/ \
	&& yq w -i /app/conf/application.yml common.build-time "$(date +"%d/%m/%Y-%H:%M:%S")"

EXPOSE 8080 2222

ENTRYPOINT ["./docker-entrypoint.sh"]
