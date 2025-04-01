# FROM ubuntu
# FROM ubuntu:20.04
FROM ubuntu:noble

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
RUN echo "Installing conda..." && \
    # curl -L -o ~/file.sh -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh" && \
    curl -L -o ~/file.sh -O https://repo.anaconda.com/miniconda/Miniconda3-latest-$(uname)-$(uname -m).sh && \
    chmod +x ~/file.sh && \
    ~/file.sh -b -p /opt/conda && \
    rm ~/file.sh  && \
    /opt/conda/bin/conda update conda -y

# set environment path
ENV PATH /opt/conda/bin:$PATH

ENV SHELL /bin/bash

WORKDIR /root

# if you don't have mamba yet, install it first:
RUN conda install -y mamba -c conda-forge

# now create a new environment
RUN mamba create -n ros_env python=3.11

SHELL ["mamba", "run", "-n", "ros_env", "/bin/bash", "-c"]

RUN echo "Add conda channels..." && \
    # conda config --env --add channels robostack && \
    # conda config --env --add channels robostack-experimental && \
    # conda config --env --add channels robostack-staging && \
    conda config --env --add channels conda-forge && \
    # conda config --env --remove channels defaults && \
    conda config --env --add channels robostack-jazzy

# Install ros-jazzy into the environment (ROS2)
RUN mamba install ros-jazzy-desktop

# optionally, install some compiler packages if you want to e.g. build packages in a colcon_ws:
RUN mamba install compilers cmake pkg-config make ninja colcon-common-extensions catkin_tools rosdep

# install jupyter-ros
# RUN mamba install jupyter jupyter-ros sqlite -c robostack

# development installation (requires npm)
RUN mamba install -c conda-forge nodejs=14 jupyterlab=3 jupyter bqplot pyyaml ipywidgets ipycanvas
RUN git clone https://github.com/RoboStack/jupyter-ros.git && \
    cd ~/jupyter-ros && \
    #git checkout 0.6.1 && \
    pip install -e . && \
    jupyter nbextension install --py --symlink --sys-prefix jupyros && \
    jupyter nbextension enable --py --sys-prefix jupyros
#     jupyter labextension develop . --overwrite && \
#     mamba install sidecar && \
#     pip install --upgrade ipympl
    

# enable bash completion
RUN echo -e "\n################### Docker config. ###################" >> ~/.bashrc && \
    echo -e "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc && \
    # https://superuser.com/questions/555310/bash-save-history-without-exit
    echo -e "export PROMPT_COMMAND='history -a'" >> ~/.bashrc && \
    echo -e "source ~/.bashrc" >> ~/.bash_profile 

CMD /opt/conda/bin/mamba run -n ros_env jupyter lab --no-browser --ip 0.0.0.0 --port=8866 --notebook-dir=/root --allow-root --NotebookApp.token='' --NotebookApp.password=''
