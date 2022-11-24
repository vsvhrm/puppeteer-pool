FROM node:16-bullseye-slim

# This image was inspired by https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md#running-puppeteer-in-docker

# Disable Chrome auto updates, based on https://support.google.com/chrome/a/answer/9052345
RUN mkdir -p /etc/default && echo 'repo_add_once=false' > /etc/default/google-chrome

# Install latest Chrome dev packages and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this also installs the necessary libs to make the bundled version of Chromium that Puppeteer installs work
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y wget gnupg ca-certificates --no-install-recommends \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | DEBIAN_FRONTEND=noninteractive apt-key add - \
    && sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && sh -c 'echo "deb http://ftp.us.debian.org/debian bullseye main non-free" >> /etc/apt/sources.list.d/fonts.list' \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    google-chrome-stable \
    fonts-freefont-ttf \
    fonts-ipafont-gothic \
    fonts-kacst \
    fonts-liberation \
    fonts-thai-tlwg \
    fonts-wqy-zenhei \
    git \
    libxss1 \
    lsb-release \
    procps \
    xdg-utils \
    --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y xvfb \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /src/*.deb \
    && mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix

# Globally disable the update-notifier.
RUN npm config --global set update-notifier false

# Install the required dependencies of chrome..by using playwright's useful CLI
RUN PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm_config_ignore_scripts=1 npx playwright install-deps chrome

# Add user so we don't need --no-sandbox.
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser

# Turn off Chrome browser component updates
RUN mkdir -p /etc/opt/chrome/policies/managed \
    && echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' > /etc/opt/chrome/policies/managed/managed_policies.json \
    && echo '{ "ComponentUpdatesEnabled": "false" }' > /etc/opt/chrome/policies/managed/component_update.json

# Run everything after as non-privileged user
USER pptruser
WORKDIR /home/pptruser

# Copy source code
COPY --chown=pptruser:pptruser . /home/pptruser/

# Skip the Chromium download when installing puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

# Sets path to Chrome executable
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome

# Tell Node.js this is a production environemnt
ENV NODE_ENV=production

# Install NPM packages, skip optional and development dependencies to
# keep the image small.
RUN npm --quiet set progress=false \
    && npm install --omit=dev --omit=optional \
    && echo "Installed NPM packages:" \
    && (npm list --omit=dev --all || true) \
    && echo "Node.js version:" \
    && node --version \
    && echo "NPM version:" \
    && npm --version \
    && echo "Google Chrome version:" \
    && bash -c "$PUPPETEER_EXECUTABLE_PATH --version"

EXPOSE 3000

CMD [ "xvfb-run", "npm", "start" ]
