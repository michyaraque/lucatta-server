FROM alpine:3.22 AS build
RUN apk add --no-cache \
  argon2-dev \
  build-base \
  boost-dev \
  cmake \
  fmt-dev \
  luajit-dev \
  mariadb-connector-c-dev \
  openssl-dev \
  pkgconf \
  protobuf \
  protobuf-dev \
  pugixml-dev \
  samurai

COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt CMakePresets.json /usr/src/forgottenserver/
WORKDIR /usr/src/forgottenserver
RUN cmake --preset default -DUSE_LUAJIT=ON && cmake --build --config RelWithDebInfo --preset default

FROM alpine:3.22
RUN apk add --no-cache \
  argon2-libs \
  boost-iostreams \
  boost-locale \
  boost-system \
  boost-json \
  fmt \
  luajit \
  mariadb-connector-c \
  openssl \
  protobuf \
  pugixml

COPY --from=build /usr/src/forgottenserver/build/RelWithDebInfo/tfs /bin/tfs
COPY data /srv/data/
COPY LICENSE README.md *.dist *.sql key.pem /srv/

EXPOSE 7171 7172
WORKDIR /srv
VOLUME /srv
ENTRYPOINT ["/bin/tfs"]
