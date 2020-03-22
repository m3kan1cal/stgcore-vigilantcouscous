# base image
FROM node

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

# Set working directory.
WORKDIR /app

# Add `/app/node_modules/.bin` to $PATH.
ENV PATH /app/node_modules/.bin:$PATH

# Install and cache app dependencies.
COPY package.json /app/package.json
RUN npm install
RUN npm install -g @angular/cli@8.1.2

# Add app to image.
COPY . /app

# Start ng app.
CMD ng serve --host 0.0.0.0
