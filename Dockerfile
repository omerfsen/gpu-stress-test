# To build faster (using previous cache)
# docker build --platform linux/amd64 -f Dockerfile . -t gpu-stress-test:<label>
# docker build --no-cache --platform linux/amd64 -f Dockerfile . -t gpu-stress-test:<label>
# Heavily modified version of https://raw.githubusercontent.com/qts8n/cuda-python/master/devel/Dockerfile
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
# sudo apt-get install -y nvidia-docker2
# and then you can run
#  docker run --gpus all  -it  gpu-stress-test:<label>
#  docker run -it --rm --runtime nvidia --network host gpu-stress-test:<label>
FROM nvidia/cuda:11.0.3-devel-ubuntu20.04
LABEL maintainer="Omer Sen <omer.x.sen@gsk.com>"

# nvidia cuda 10.2 paths
ENV LD_LIBRARY_PATH=/usr/local/cuda-11.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV LIBRARY_PATH=${LIBRARY_PATH}:/usr/local/cuda-11.0/lib64

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

ENV LANG C.UTF-8

# ensure annoying packages like `tzdata` won't ask a lot of questions
ARG DEBIAN_FRONTEND=noninteractive

# runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl netbase wget && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get install -y build-essential

ENV GPG_KEY a035c8c19219ba821ecea86b64e628f8d684696d
ENV PYTHON_VERSION 3.10.5

RUN mkdir ~/.gnupg
RUN echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf
RUN set -ex \
	&& savedAptMark="$(apt-mark showmanual)" \
	&& echo "Europe/London" > /etc/timezone \
	&& apt-get update \
    && apt-get install -y --no-install-recommends \
        dpkg-dev \
        gcc \
        libbz2-dev \
        libc6-dev \
        libexpat1-dev \
        libffi-dev \
        libgdbm-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        make \
        tk-dev \
        uuid-dev \
        xz-utils \
        zlib1g-dev \
        $(command -v gpg > /dev/null || echo 'gnupg dirmngr') \
    && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&&  gpg --batch --keyserver hkps://keys.openpgp.org  --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	&& make -j "$(nproc)" \
    PROFILE_TASK='-m test.regrtest --pgo \
        test_array \
        test_base64 \
        test_binascii \
        test_binhex \
        test_binop \
        test_bytes \
        test_c_locale_coercion \
        test_class \
        test_cmath \
        test_codecs \
        test_compile \
        test_complex \
        test_csv \
        test_decimal \
        test_dict \
        test_float \
        test_fstring \
        test_hashlib \
        test_io \
        test_iter \
        test_json \
        test_long \
        test_math \
        test_memoryview \
        test_pickle \
        test_re \
        test_set \
        test_slice \
        test_struct \
        test_threading \
        test_time \
        test_traceback \
        test_unicode \
    ' \
	&& make install \
	&& ldconfig \
	&& apt-mark auto '.*' > /dev/null \
	&& apt-mark manual $savedAptMark \
	&& find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& rm -rf /var/lib/apt/lists/* \
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	&& python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# if this is called "PIP_VERSION", pip throws "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 22.2
ENV PYTHON_GET_PIP_URL https://bootstrap.pypa.io/pip/get-pip.py
ENV PYTHON_GET_PIP_SHA256 d077d469ce4c0beaf9cc97b73f8164ad20e68e0519f14dd886ce35d053721501

RUN set -ex; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends wget; \
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION"; \
	pip --version; \
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

# Find matching versions at https://download.pytorch.org/whl/torch_stable.html
RUN pip3 install torch==1.12.0+cu116 torchvision==0.13.0+cu116 torchaudio==0.12.0+cu116 cuda-python==11.6.1 -f https://download.pytorch.org/whl/torch_stable.html && rm -fr ${HOME}/.cache

RUN apt-get -y autoremove \
    && apt-get -y clean

COPY . .

ENTRYPOINT [ "python3", "stress.py"]
CMD ["-m 5"]
