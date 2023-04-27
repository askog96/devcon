FROM ubuntu:jammy

# Installing required packages
RUN apt-get update -y 
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    gnupg \
    build-essential \
    vim \
    git \
    curl \
    cmake \
    wget \
    sudo \
    iputils-ping \
    ssh \
    ansible \
    netcat \
    python-setuptools \
    python3-pip \
    zip \
    unzip \
    jq \
    tree \
    maven \
    locate \
    rsync \
    bash-completion \
    apt-transport-https \
    dnsutils \
    software-properties-common \
    ca-certificates \
    zsh \
    fonts-powerline \
    nodejs \
    npm \ 
    iproute2 \
    file \
    graphviz \
    less \
    postgresql \
    postgresql-contrib \
    redis \
    && rm -rf /var/lib/apt/lists/*

# Package Versions
ENV GOLANG_VERSION 1.20.3
ENV GOLANG_DOWNLOAD_SHA256 eb186529f13f901e7a2c4438a05c2cd90d74706aaa0a888469b2a4a617b6ee54
ENV TERRAFORM_VERSION 1.4.5
#ENV TECLI_VERSION 0.2.0
ENV VAULT_VERSION 1.13.0
ENV CONSUL_VERSION 1.15.0
ENV PACKER_VERSION 1.8.5
ENV BOUNDARY_VERSION 0.12.1
ENV WAYPOINT_VERSION 0.11.0
ENV KUBECTL_VER 1.25.2
ENV HELM_VERSION 3.8.1
ENV CALICO_VERSION 3.16.1

# Installaing Docker CLI & Docker Compose
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get -y install docker-ce-cli docker-compose-plugin

# Installing Additional PIP based libraries
RUN pip install \
    six \
    docker \
    httpie \
    python-bash-utils \
    pywinrm \
    xmltodict \
    pyOpenSSL==16.2.0 

# Installing + Setting Up GO Environment
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-arm64.tar.gz
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& sudo tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

# Setting up GOPATH. For me, i'm using $HOME/code/go
ENV HOME /root
ENV GOPATH $HOME/code/go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

# Installing HashiCorp Stack
# Installing Terraform 
RUN curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm64.zip -o terraform.zip
RUN unzip terraform.zip  -d /usr/local/bin  
RUN rm terraform.zip

# Installing tecli ( Terraform Cloud/Enterprise CLI)
#RUN wget https://github.com/awslabs/tecli/releases/download/${TECLI_VERSION}/tecli-linux-arm64 -O /usr/local/bin/tecli && chmod +x /usr/local/bin/tecli

# Installing Vault
RUN curl https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_arm64.zip -o vault.zip
RUN unzip vault.zip  -d /usr/local/bin  
RUN rm vault.zip

# Installing Packer
RUN curl https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_arm64.zip -o packer.zip
RUN unzip packer.zip -d /usr/local/bin
RUN rm packer.zip

# Installing Boundary
RUN curl https://releases.hashicorp.com/boundary/${BOUNDARY_VERSION}/boundary_${BOUNDARY_VERSION}_linux_arm64.zip -o boundary.zip
RUN unzip boundary.zip -d /usr/local/bin
RUN rm boundary.zip

# Installing Consul 
RUN curl https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_arm64.zip -o consul.zip
RUN unzip consul.zip -d /usr/local/bin
RUN rm consul.zip

# Installing Waypoint
RUN curl -fsSl https://releases.hashicorp.com/waypoint/${WAYPOINT_VERSION}/waypoint_${WAYPOINT_VERSION}_linux_arm64.zip -o waypoint.zip
RUN unzip waypoint.zip -d /usr/local/bin
RUN rm waypoint.zip

# Installing ccat (https://github.com/jingweno/ccat)
RUN go install github.com/jingweno/ccat@latest
# Installing CFSSL (https://github.com/cloudflare/cfssl)
RUN go install github.com/cloudflare/cfssl/cmd/cfssl@latest

# Installing gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y

# Kubernetes Tools : kubectl, kubectx, and kubens
RUN wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O /usr/local/bin/kubectx && chmod +x /usr/local/bin/kubectx
RUN wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O /usr/local/bin/kubens && chmod +x /usr/local/bin/kubens
RUN wget https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VER/bin/linux/arm64/kubectl -O /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# Installing Helm
RUN wget https://get.helm.sh/helm-v$HELM_VERSION-linux-arm64.tar.gz -O /tmp/helm-v$HELM_VERSION-linux-arm64.tar.gz && \
    tar -zxvf /tmp/helm-v$HELM_VERSION-linux-arm64.tar.gz && \
    mv linux-arm64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm

# Installing Krew
RUN OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/arm4/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf ${KREW}.tar.gz && \
    KREW=./krew-"${OS}_${ARCH}" && \
    "$KREW" install krew && \
    cp $HOME/.krew/bin/kubectl-krew /usr/local/bin/

# Install netshoot kubcetl plugin
RUN go install github.com/nilic/kubectl-netshoot@latest

# Installing eksctl
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_arm64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin

# Installing calicoctl
RUN wget https://github.com/projectcalico/calicoctl/releases/download/v$CALICO_VERSION/calicoctl -O /usr/local/bin/calicoctl && chmod +x /usr/local/bin/calicoctl

# Installing Azure CLI
# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Installing Sigstore Cosign (https://github.com/sigstore/cosign)
RUN wget https://github.com/sigstore/cosign/releases/download/v1.8.0/cosign-linux-arm64 -O /usr/local/bin/cosign && chmod +x /usr/local/bin/cosign

# Installing Snyk CLI
RUN curl https://static.snyk.io/cli/latest/snyk-linux -o /usr/local/bin/snyk && chmod +x /usr/local/bin/snyk

# Installing AWS CLI v2 + Session Manager + IAM Authenticator
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install
RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb" && dpkg -i session-manager-plugin.deb
RUN curl "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_arm64" -o /usr/local/bin/aws-iam-authenticator && chmod +x /usr/local/bin/aws-iam-authenticator

# Installing Infracost CLI
RUN wget https://github.com/infracost/infracost/releases/download/v0.10.8/infracost-linux-arm64.tar.gz
RUN tar xzf infracost-linux-arm64.tar.gz -C /tmp
RUN mv /tmp/infracost-linux-arm64 /usr/local/bin/infracost

# Setting WORKDIR and USER 
USER root
WORKDIR /root
VOLUME ["/home/devcon"]

# ZSH ENVs
ENV TERM xterm
ENV ZSH_THEME agnoster
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
COPY zshrc .zshrc

# Running ZSH
CMD ["zsh"]
