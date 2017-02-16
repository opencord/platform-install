# To build use: docker build -t xosproject/xos-gui-extension-builder .

FROM node:argon

# Set environment vars
ENV CODE_SOURCE .
ENV CODE_DEST /var/www

# Add the app deps
COPY ${CODE_SOURCE}/package.json ${CODE_DEST}/package.json
COPY ${CODE_SOURCE}/typings.json ${CODE_DEST}/typings.json

# Install Deps
WORKDIR ${CODE_DEST}
RUN npm install
RUN npm run typings
RUN npm install -g gulp
RUN npm install -g typings
