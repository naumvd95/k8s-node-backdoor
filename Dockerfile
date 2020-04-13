#FROM alpine:3.11.5
# TODO get rid of ubuntu
FROM ubuntu

# Forward volumes with authorized_keys from node 
# Managed in etrypoint.sh
ENV AUTHORIZED_KEYS_PATH /ssh-input/authorized_keys

ADD nodebackdoor /bin/nodebackdoor
ADD id_rsa.pub /ssh-input/id_rsa.pub
ADD entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT  ["/bin/entrypoint.sh"]
CMD ["--public-key /ssh-input/id_rsa.pub"]
