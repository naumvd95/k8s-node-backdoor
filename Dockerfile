FROM alpine:3.11.5

# Forward volumes with authorized_keys from node 
ENV PUBLIC_KEY_PATH /ssh-input/id_rsa.pub

ADD nodebackdoor /bin/nodebackdoor
ADD id_rsa.pub ${PUBLIC_KEY_PATH}

ENTRYPOINT  ["nodebackdoor"]
CMD  ["daemon", "--forward-ssh", "--collect-logs"]
