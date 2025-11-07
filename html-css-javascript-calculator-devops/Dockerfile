FROM nginx:stable-alpine AS runtime
RUN rm -rf /usr/share/nginx/html/*
COPY src/ /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s CMD ["/bin/sh", "-c", "wget -qO- --timeout=2 http://localhost/ || exit 1"]
CMD ["nginx", "-g", "daemon off;"]
