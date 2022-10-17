FROM ubuntu

LABEL maintainer="Waipot Ngamsaad <waipotn@hotmail.com>"

ARG MINICONDA_SH=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install --reinstall ca-certificates -y

RUN sed -i -e 's/http:\/\/archive/mirror:\/\/mirrors/' -e 's/http:\/\/security/mirror:\/\/mirrors/' -e 's/\/ubuntu\//\/mirrors.txt/' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    git \
    curl \
    locales \
    gnupg2 \
    lsb-release \
    sudo && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8     

# install Miniconda3
RUN curl -o ~/miniconda.sh -O $MINICONDA_SH && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh 

# set environment path
ENV PATH /opt/conda/bin:$PATH

# setup user
RUN useradd -m developer && \
    usermod -aG sudo developer && \
    usermod --shell /bin/bash developer && \
    #chown -R developer:developer /workspace && \
    #ln -sfn /workspace /home/developer/workspace && \
    echo developer ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

#USER developer

# if you don't have mamba yet, install it first:
RUN conda install -y mamba -c conda-forge

# now create a new environment
#RUN mamba create -y -n ros_humble ros-humble-desktop python=3.9 -c robostack-humble -c conda-forge --no-channel-priority --override-channels
#RUN conda activate ros_humble
#RUN mamba install -y ros-humble-desktop python=3.9 -c robostack-humble -c conda-forge --no-channel-priority --override-channels
RUN mamba create -y -n ros_humble python=3.9 jupyterlab jupyter-packaging bqplot pyyaml ipywidgets ipycanvas ros-humble-desktop-full -c conda-forge -c robostack -c robostack-humble -c robostack-experimental

# Add env in Dockerfile: 
# https://medium.com/@chadlagore/conda-environments-with-docker-82cdc9d25754
# https://stackoverflow.com/questions/55123637/activate-conda-environment-in-docker
RUN echo "source activate ros_humble" > ~/.bashrc
ENV PATH /opt/conda/envs/ros_humble/bin:$PATH

# optionally, install some compiler packages if you want to e.g. build packages in a colcon_ws:
RUN mamba install -y compilers cmake pkg-config make ninja colcon-common-extensions -c conda-forge

# on Windows, install Visual Studio 2017 or 2019 with C++ support 
# see https://docs.microsoft.com/en-us/cpp/build/vscpp-step-0-installation?view=msvc-160

# on Windows, install the Visual Studio command prompt via Conda:
#RUN mamba install -y vs2019_win-64 -c conda-forge -c robostack-humble

# note that in this case, you should also install the necessary dependencies with conda/mamba, if possible

# reload environment to activate required scripts before running anything
# on Windows, please restart the Anaconda Prompt / Command Prompt!
#RUN conda deactivate
#RUN conda activate ros_humble

# if you want to use rosdep, also do:
RUN mamba install -y rosdep -c conda-forge
RUN rosdep init  # note: do not use sudo!
RUN rosdep update

RUN conda config --env --add channels conda-forge &&\
    conda config --env --add channels robostack &&\
    conda config --env --add channels robostack-experimental

RUN conda install -y jupyter bqplot pyyaml ipywidgets ipycanvas

# install nodejs
RUN sh -c 'echo "deb https://deb.nodesource.com/node_16.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodesource.list' && \
    curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
    nodejs \
	&& rm -rf /var/lib/apt/lists/*

RUN cd ~ && git clone https://github.com/RoboStack/jupyter-ros.git && cd jupyter-ros && git checkout v0.6.0a0
RUN cd ~/jupyter-ros && pip install -e .

RUN conda install -c conda-forge jupyter_contrib_nbextensions
#RUN conda run -n ros_humble jupyter nbextension install --py --symlink --sys-prefix jupyros &&\
#    conda run -n ros_humble jupyter nbextension enable --py --sys-prefix jupyros

CMD conda run -n ros_humble jupyter lab --no-browser --ip 0.0.0.0 --port=8888 --notebook-dir=$HOME --allow-root