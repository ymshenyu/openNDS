
CC=gcc
CFLAGS=-O2 -Isrc -Ilibhttpd -fhonour-copts
#CFLAGS+=-Wall -Wwrite-strings -pedantic -std=gnu99
LDFLAGS=-lpthread

NDS_OBJS=src/auth.o src/client_list.o src/commandline.o src/conf.o \
	src/debug.o src/firewall.o src/fw_iptables.o src/gateway.o src/http.o \
	src/httpd_thread.o src/ndsctl_thread.o src/safe.o src/tc.o src/util.o

LIBHTTPD_OBJS=libhttpd/api.o libhttpd/ip_acl.o \
	libhttpd/protocol.o libhttpd/version.o

OBJS=$(NDS_OBJS) $(LIBHTTPD_OBJS)

.PHONY: all clean install

all: nodogsplash ndsctl

%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

nodogsplash: $(OBJS)
	$(CC) $(LDFLAGS) -o nodogsplash $+

ndsctl: src/ndsctl.o
	$(CC) $(LDFLAGS) -o ndsctl $+

clean:
	rm -f nodogsplash ndsctl src/*.o libhttpd/*.o

install:
	strip nodogsplash
	strip ndsctl
	mkdir -p /usr/bin/
	cp ndsctl /usr/bin/
	cp nodogsplash /usr/bin/
	mkdir -p /etc/nodogsplash/htdocs/images
	cp resources/nodogsplash.conf /etc/nodogsplash/
	cp resources/splash.html /etc/nodogsplash/htdocs/
	cp resources/infoskel.html /etc/nodogsplash/htdocs/
	cp resources/splash.jpg /etc/nodogsplash/htdocs/images/