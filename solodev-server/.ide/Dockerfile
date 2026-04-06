# .ide/Dockerfile

# 可将 node 替换为需要的基础镜像
FROM ruby:3.4.4

# 安装 code-server 和 vscode 常用插件
RUN curl -fsSL https://code-server.dev/install.sh | sh \
  && code-server --install-extension cnbcool.cnb-welcome \
  && code-server --install-extension redhat.vscode-yaml \
  && code-server --install-extension dbaeumer.vscode-eslint \
  && code-server --install-extension waderyan.gitblame \
  && code-server --install-extension mhutchie.git-graph \
  && code-server --install-extension donjayamanne.githistory \
  && code-server --install-extension ms-ceintl.vscode-language-pack-zh-hans \
  && code-server --install-extension tencent-cloud.coding-copilot \
  && code-server --install-extension alibaba-cloud.tongyi-lingma \
  && echo done





# 安装 ssh 服务，用于支持 VSCode 客户端通过 Remote-SSH 访问开发环境
RUN apt-get update && \
    apt-get install -y jq 

# 修改 gem 源
RUN gem sources --remove https://rubygems.org/ && \
    gem sources --add https://mirrors.cloud.tencent.com/rubygems/

# 生成中文插件必要的配置文件
COPY .ide/create_languagepacks /tmp/create_languagepacks 
RUN chmod +x /tmp/create_languagepacks && \
    /tmp/create_languagepacks && \
    rm -f /tmp/create_languagepacks





# 指定字符集支持命令行输入中文（根据需要选择字符集）
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8