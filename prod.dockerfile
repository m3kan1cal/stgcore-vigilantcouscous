#############
### build ###
#############

# base image
FROM node as build

# Install latest chrome dev package, which installs the necessary libs to
# make the bundled version of Chromium that Puppeteer installs work.
RUN  apt-get update \
     && apt-get install -y wget --no-install-recommends \
     && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
     && apt-get update \
     && apt-get install -y google-chrome-unstable --no-install-recommends \
     && rm -rf /var/lib/apt/lists/* \
     && wget --quiet https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -O /usr/sbin/wait-for-it.sh \
     && chmod +x /usr/sbin/wait-for-it.sh

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY package.json /app/package.json
RUN npm install
RUN npm install -g @angular/cli@8.1.2

# add app
COPY . /app

# run tests
RUN ng test --watch=false
RUN ng e2e --port 4202

# generate build, override base href
RUN ng build --base-href=/vigilantcouscous/ --output-path=dist

############
### prod ###
############

# base image
FROM nginx

# install dependencies
RUN apt-get update && apt-get install -y curl \
     && apt-get clean

# copy artifact build from the 'build environment'
COPY --from=build /app/dist /var/www/html/vigilantcouscous

# override location directives
COPY --from=build /app/default.conf /etc/nginx/conf.d/default.conf

# expose port 80
EXPOSE 80

# set container health check
# HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost/ || exit 1

# run nginx
CMD ["nginx", "-g", "daemon off;"]
