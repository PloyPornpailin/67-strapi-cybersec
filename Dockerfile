FROM node:20-alpine as build

RUN apk update; \
    apk upgrade;

RUN apk add --update nodejs; \
    apk add --update npm;

RUN npm cache clean -f; \
    npm install n -g; \
    n stable; \
    npm update -g; \
    npm install npm@latest -g;

RUN SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm_config_arch=x64 npm_config_platform=linuxmusl yarn add sharp@0.32.1

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /opt/
COPY package.json yarn.lock ./
RUN npm config set network-timeout 600000 -g && npm run install --production
ENV PATH /opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY . .
RUN nmp build

# Creating final production image
FROM node:20-alpine
RUN apk add
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /opt/
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./
ENV PATH /opt/node_modules/.bin:$PATH

RUN chown -R node:node /opt/app
USER node
EXPOSE 1337
CMD ["npm", "run", "start"]