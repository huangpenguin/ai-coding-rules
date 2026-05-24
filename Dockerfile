FROM pytorch/pytorch:2.2.1-cuda12.1-cudnn8-devel

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    TZ=Asia/Shanghai

RUN ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        openssh-client \
        tini \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

WORKDIR /workspace

ENTRYPOINT ["tini", "--"]
CMD ["bash"]
