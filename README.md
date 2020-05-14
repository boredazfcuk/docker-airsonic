# docker-airsonic
Stack:steve An Alpine Linux Docker container for Airsonic

# IMPORTANT INFO

This image is designed to be run in my stack 'steve'. It may not work correctly as a standalone container as I do not test it in that capacity.

The purpose of the stack is to manage all of your media, provide a central database for metadata, allow remote access to your collection while also providing security and anonymity.

This service in the stack depends on a separate container with an OpenVPN connection and it's web-based interface should be accessed using an NGINX reverse proxy which is secured with LetsEncrypt certificates.

Those containers are available as boredafcuk/docker-openvpnpia and boredazfcuk/docker-nginx on Github and are on Docker Hub as boredazfcuk/openvpnpia and boredazfcuk/nginx.

The stack's docker-compose.yaml is available on GitHub boredazfcuk/steve

### ENVIRONMENT VARIABLES

stack_user: This is name of the user account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user on the host system which has access to your storage.

user_id: This is the User ID number of the above user account. This can be any number that isn't already in use. Ideally, you should set this to be the same ID number as the USER's ID on the host system. This will avoid permissions issues on the host system.

airsonic_group: This is name of the group account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user's primary group on the host system.

airsonic_group_id: This is the Group ID number of the above group. This can be any number that isn't already in use. Ideally, you should set this to be the same Group ID number as the user's primary group on the host system.

### VOLUME CONFIGURATION

This container requires a named volume mapped to /config/ This is where is stores the airsonic configuration, database and logs. If this isn't created as a named volume, then you risk losing your DB and config when recreating the container.

This container also requires a bind mount, in which your movies are stored, and it should be mapped to /storage/

### CREATING A CONTAINER

To create this container, download the docker-compose.yaml for my stack 'steve', change the variable in the environment file and just 'up' it.
