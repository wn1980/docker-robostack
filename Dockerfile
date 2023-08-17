FROM ubuntu
#FROM ubuntu:20.04
#FROM ros:humble-ros-base-jammy

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

# install nodejs
#RUN sh -c 'echo "deb https://deb.nodesource.com/node_14.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodesource.list' && \
#    curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

#RUN apt-get update && apt-get upgrade -y
#RUN apt-get install -y \
#    nodejs \
#	&& rm -rf /var/lib/apt/lists/*

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
#RUN mamba create -y -n ros_humble ros-humble-desktop python=3.9 -c robostack-humble -c conda-forge --no-channel-priority --override-channels
#RUN conda activate ros_humble
#RUN mamba install -y ros-humble-desktop python=3.9 -c robostack-humble -c conda-forge --no-channel-priority --override-channels
#RUN mamba create -y -n ros_humble python=3.9 jupyterlab jupyter-packaging bqplot pyyaml ipywidgets ipycanvas ros-humble-desktop-full -c conda-forge -c robostack -c robostack-humble -c robostack-experimental
RUN mamba create -n ros_env python=3.9

SHELL ["mamba", "run", "-n", "ros_env", "/bin/bash", "-c"]

RUN conda config --env --add channels robostack && \
    conda config --env --add channels robostack-humble && \
    conda config --env --add channels robostack-experimental && \
    conda config --env --add channels robostack-staging && \
    conda config --env --add channels conda-forge

# Install ros-humble into the environment (ROS2)
RUN mamba install ros-humble-turtlesim

# Add env in Dockerfile: 
# https://medium.com/@chadlagore/conda-environments-with-docker-82cdc9d25754
# https://stackoverflow.com/questions/55123637/activate-conda-environment-in-docker
#RUN echo "source activate ros_humble" > ~/.bashrc
#ENV PATH /home/developer/conda/envs/ros_humble/bin:$PATH

# optionally, install some compiler packages if you want to e.g. build packages in a colcon_ws:
#RUN mamba install -y compilers cmake pkg-config make ninja colcon-common-extensions -c conda-forge
RUN mamba install compilers cmake pkg-config make ninja colcon-common-extensions catkin_tools


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
#RUN mamba install -y rosdep -c conda-forge
RUN mamba install jupyterlab jupyter-packaging bqplot pyyaml ipywidgets ipycanvas jupyter-ros

#RUN cd ~ && git clone https://github.com/RoboStack/jupyter-ros.git && cd jupyter-ros && git checkout v0.6.0a0
#RUN cd ~/jupyter-ros && pip install -e .

#RUN conda install -c conda-forge jupyter_contrib_nbextensions
#RUN conda run -n ros_humble jupyter nbextension install --py --symlink --sys-prefix jupyros &&\
#    conda run -n ros_humble jupyter nbextension enable --py --sys-prefix jupyros

RUN git clone https://github.com/RoboStack/jupyter-ros.git && \
    mv jupyter-ros/notebooks /root && \
    rm -rf jupyter-ros

# enable bash completion
RUN echo -e "\n################### Docker config. ###################" >> ~/.bashrc && \
    echo -e "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc && \
    # https://superuser.com/questions/555310/bash-save-history-without-exit
    echo -e "export PROMPT_COMMAND='history -a'" >> ~/.bashrc && \
    echo -e "source ~/.bashrc" >> ~/.bash_profile 

CMD /opt/conda/bin/mamba run -n ros_env jupyter lab --no-browser --ip 0.0.0.0 --port=8866 --notebook-dir=/root --allow-root --NotebookApp.token='' --NotebookApp.password=''
