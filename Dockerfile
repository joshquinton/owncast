# IMPORTANT: This Dockerfile has been provided for the sake of convenience.
# Currently, functionality of the containers built based on this file
# is not a part of our continuous testing. Although, patches to keep it
# up to date are always welcome.
#
# See ‘Earthfile’ for the recipes used in official builds.

FROM debian:trixie-slim AS build

RUN apt-get update && apt-get install -y git golang build-essential

WORKDIR /build
COPY . /build

ARG VERSION=dev
ENV VERSION=${VERSION}
ARG GIT_COMMIT
ENV GIT_COMMIT=${GIT_COMMIT}
ARG NAME=docker
ENV NAME=${NAME}

RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -ldflags "-extldflags \"-static\" -s -w -X github.com/owncast/owncast/config.GitCommit=$GIT_COMMIT -X github.com/owncast/owncast/config.VersionNumber=$VERSION -X github.com/owncast/owncast/config.BuildPlatform=$NAME" -o owncast .

# Create the image by copying the result of the build into a new Debian image
FROM debian:13.0-slim
RUN apt-get update && apt-get install -y ffmpeg ca-certificates && update-ca-certificates

RUN groupadd -g 101 owncast && useradd owncast -u 101 -g owncast

# Copy owncast assets
WORKDIR /app
COPY --from=build /build/owncast /app/owncast
RUN mkdir /app/data
RUN chown -R owncast:owncast /app
USER owncast
ENTRYPOINT ["/app/owncast"]
EXPOSE 8080 1935
