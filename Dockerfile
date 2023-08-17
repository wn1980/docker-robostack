FROM ubuntu
#FROM ubuntu:20.04

LABEL maintainer="Waipot Ngamsaad <waipotn@hotmail.com>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install --reinstall ca-certificates -y

#RUN sed -i -e 's/http:\/\/archive/mirror:\/\/mirrors/' -e 's/http:\/\/security/mirror:\/\/mirrors/' -e 's/\/ubuntu\//\/mirrors.txt/' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    git \
    curl \
    locales \
    gnupg2 \
    lsb-release \
    nano \
    bash-completion \
    sudo && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install Miniconda3
RUN curl -L -o ~/file.sh -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh" && \
    #curl -L -o ~/file.sh -O https://repo.anaconda.com/miniconda/Miniconda3-latest-$(uname)-$(uname -m).sh && \
    chmod +x ~/file.sh && \
    ~/file.sh -b -p /opt/conda && \
    rm ~/file.sh 

# set environment path
ENV PATH /opt/conda/bin:$PATH

ENV SHELL /bin/bash

WORKDIR /root

# if you don't have mamba yet, install it first:
RUN conda install -y mamba -c conda-forge

# now create a new environment
RUN mamba create -n ros_env python=3.9

SHELL ["mamba", "run", "-n", "ros_env", "/bin/bash", "-c"]

RUN conda config --env --add channels robostack && \
    conda config --env --add channels robostack-humble && \
    conda config --env --add channels robostack-experimental && \
    conda config --env --add channels robostack-staging && \
    conda config --env --add channels conda-forge

# Install ros-humble into the environment (ROS2)
RUN mamba install ros-humble-desktop

# optionally, install some compiler packages if you want to e.g. build packages in a colcon_ws:
RUN mamba install compilers cmake pkg-config make ninja colcon-common-extensions catkin_tools

RUN mamba install jupyterlab jupyter-packaging bqplot pyyaml ipywidgets ipycanvas nodejs=14

RUN git clone https://github.com/RoboStack/jupyter-ros.git && \
    cd ~/jupyter-ros && \
    #git checkout 0.6.1 && \
    pip install -e . && \
    jupyter labextension develop . --overwrite 

# enable bash completion
RUN echo -e "\n################### Docker config. ###################" >> ~/.bashrc && \
    echo -e "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc && \
    # https://superuser.com/questions/555310/bash-save-history-without-exit
    echo -e "export PROMPT_COMMAND='history -a'" >> ~/.bashrc && \
    echo -e "source ~/.bashrc" >> ~/.bash_profile 

CMD /opt/conda/bin/mamba run -n ros_env jupyter lab --no-browser --ip 0.0.0.0 --port=8866 --notebook-dir=/root --allow-root --NotebookApp.token='' --NotebookApp.password=''
