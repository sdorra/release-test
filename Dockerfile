FROM alpine:3.7
COPY target/yubiauth /yubiauth
CMD [ "/yubiauth" ]
