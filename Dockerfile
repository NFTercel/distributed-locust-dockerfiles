FROM python:3.7-alpine3.9

RUN apk --no-cache add g++ \
      && apk --no-cache add zeromq-dev \
      && pip install locustio pyzmq awscli

EXPOSE 8089 5557 5558

WORKDIR /workspace
ADD . /workspace

ENTRYPOINT ["/bin/sh", "/workspace/main.sh"]