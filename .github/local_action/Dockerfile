FROM dwpdigital/tflint:latest

COPY entrypoint.sh /entrypoint.sh
RUN pwd && ls && cat /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
