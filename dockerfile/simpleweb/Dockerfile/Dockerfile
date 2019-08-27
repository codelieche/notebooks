#FROM scratch
FROM busybox:latest

WORKDIR /app

ENV HOST="0.0.0.0" PORT=80 DURATION=35
EXPOSE $PORT

COPY ./app /app/app

# 如果FROM其它的系统就从下面的命令启动
CMD ["/bin/sh", "-c", "/app/app --host=$HOST --port=$PORT --duration=$DURATION"]

# FROM scratch的话，用这个命令启动
#CMD ["/app/app"]
