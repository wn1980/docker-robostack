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

# install conda
RUN echo "Installing conda..." && \
    curl -L -o ~/file.sh -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    # curl -L -o ~/file.sh -O https://repo.anaconda.com/miniconda/Miniconda3-latest-$(uname)-$(uname -m).sh && \
    chmod +x ~/file.sh && \
    ~/file.sh -b -p /opt/conda && \
    rm ~/file.sh  && \
    /opt/conda/bin/conda update conda -y

# set environment path
ENV PATH /opt/conda/bin:$PATH

# ======================== BEGIN: Create a user ========================
ENV USERNAME "ubuntu"
ENV USER ${USERNAME}
ENV HOME /home/${USERNAME}
ENV SHELL /bin/bash
ENV PATH /home/${USERNAME}/.local/bin:$PATH

# setup user space
RUN mkdir -p /workspace /opt/conda
RUN echo "Creating user: ${USERNAME}" && \
    # useradd -m ${USERNAME} && \
    usermod -aG sudo ${USERNAME} && \
    usermod -aG dialout ${USERNAME} && \
    usermod -aG video ${USERNAME} && \
    usermod --shell /bin/bash ${USERNAME} && \
    echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME} && \
    chown -R ${USERNAME}:${USERNAME} /workspace && \
    ln -sfn /workspace /home/${USERNAME}/workspace && \
    chown -R ${USERNAME}:${USERNAME} /opt/conda && \ 
    ls -la /home/${USERNAME}

# Enter to User mode
USER ${USERNAME}
WORKDIR /home/${USERNAME}
# ======================== END: Create a user ========================

# if you don't have mamba yet, install it first:
RUN conda install -y mamba -c conda-forge

# now create a new environment
RUN mamba create -n ros_env python=3.11

SHELL ["mamba", "run", "-n", "ros_env", "/bin/bash", "-c"]

RUN echo "Add conda channels..." && \
    conda config --env --add channels conda-forge && \
    # conda config --env --remove channels defaults && \
    conda config --env --add channels robostack-jazzy

# IMPORTANT!: install jupyter-ros (BEFORE installing any ros packages?)
# RUN mamba install jupyter-ros -c robostack # (pre-built package does not work?)

# development installation (requires npm)
RUN mamba install nodejs=14 jupyterlab=3 jupyter bqplot pyyaml ipywidgets ipycanvas -c conda-forge
RUN git clone https://github.com/RoboStack/jupyter-ros.git /opt/conda/.jupyter-ros && \
    cd /opt/conda/.jupyter-ros && \
    # git checkout 0.7.0 && \
    pip install -e . && \
    jupyter nbextension install --py --symlink --sys-prefix jupyros && \
    jupyter nbextension enable --py --sys-prefix jupyros && \
    jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
    jupyter labextension develop . --overwrite && \
    mamba install sidecar numpy matplotlib && \
    # pip install --upgrade ipympl && \
    cp -rf ./notebooks /workspace && \
    echo "Done!"

# Install ros-jazzy into the environment (ROS2)
RUN mamba install \
    ros-jazzy-ros-core \
    ros-jazzy-turtlesim
    # ros-jazzy-ros-base 
    # ros-jazzy-desktop

# optionally, install some compiler packages if you want to e.g. build packages in a colcon_ws:
# RUN mamba install compilers cmake pkg-config make ninja colcon-common-extensions catkin_tools rosdep

# switch to normal bash 
SHELL ["/bin/bash", "-c"]

RUN conda init bash && conda config --set auto_activate_base false

# enable bash completion
RUN echo -e "\n################### Docker config. ###################" >> ~/.bashrc && \
    echo -e "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc && \
    # https://superuser.com/questions/555310/bash-save-history-without-exit
    echo -e "export PROMPT_COMMAND='history -a'" >> ~/.bashrc && \
    echo -e "source ~/.bashrc" >> ~/.bash_profile && \
    source ~/.bashrc

# Clean
RUN sudo apt-get -y autoremove && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

CMD /opt/conda/bin/mamba run -n ros_env jupyter lab --no-browser --ip 0.0.0.0 --port=8866 --notebook-dir=/workspace --allow-root --NotebookApp.token='' --NotebookApp.password=''
