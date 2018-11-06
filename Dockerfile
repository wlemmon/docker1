FROM ubuntu:14.04
MAINTAINER Matthieu Lagacherie <matthieu.lagacherie __AT__ gmail __DOT__ com>

RUN locale-gen fr_FR.UTF-8 && \
    echo 'LANG="fr_FR.UTF-8"' > /etc/default/locale

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

# Install miniconda Python distribution
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# Install miniconda Python distribution
#RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
#    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-4.3.11-Linux-x86_64.sh -O ~/miniconda.sh && \
#    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
#    rm ~/miniconda.sh

RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

ENV PATH /opt/conda/bin:$PATH

# Install python packages
RUN conda install -y notebook scikit-learn pandas matplotlib networkx tensorflow-gpu keras pytorch torchvision
RUN conda install -c conda-forge jupyter_contrib_nbextensions jupyter_nbextensions_configurator

# Install Gym
RUN pip install git+https://github.com/openai/gym.git
#RUN rm /usr/bin/python-config
#RUN ln -s /usr/bin/python3.6-config /usr/bin/python-config

# Download ns3
RUN mkdir /opt/ns
WORKDIR /opt/ns
RUN wget https://www.nsnam.org/release/ns-allinone-3.26.tar.bz2 && tar xjf ns-allinone-3.26.tar.bz2 && rm ns-allinone-3.26.tar.bz2


# Install ns3 dependencies
RUN apt-get install --yes python-software-properties software-properties-common
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get update
RUN apt-get install --yes wget make clang-3.5 python-dev libgsl0-dev gcc-5 g++-5 cgdb
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 --slave /usr/bin/g++ g++ /usr/bin/g++-5

# Try Python 3
RUN add-apt-repository ppa:fkrull/deadsnakes && apt-get update && apt-get install -y python3.6-dev

# Remove Python 2.7
RUN apt-get autoremove --purge -y python python2.7

RUN pip install pygccxml

# Install ns3
WORKDIR /opt/ns/ns-allinone-3.26
RUN ./build.py --enable-examples --enable-tests -- --python=/usr/bin/python3.6

WORKDIR /opt/ns/ns-allinone-3.26/ns-3.26
#RUN ./test.py core

RUN apt-get update && apt-get install --yes --no-install-recommends netanim cmake-curses-gui libboost-graph-dev

# Optimize Image Size
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN touch /root/.bashrc && echo "export PYTHONPATH='/opt/ns/ns-allinone-3.26/ns-3.26/build/bindings/python:/opt/ns/ns-allinone-3.26/ns-3.26/src/visualizer:/opt/ns/ns-allinone-3.26/pybindgen-0.17.0.post57+nga6376f2'" >> /root/.bashrc && echo "export LD_LIBRARY_PATH='/usr/lib/gcc/x86_64-linux-gnu/5:/opt/ns/ns-allinone-3.26/ns-3.26/build'" >> /root/.bashrc


EXPOSE 8888

CMD /bin/bashs
