ARG FUNCTION_DIR="/function"

FROM continuumio/miniconda3

RUN echo "python==3.8" >> /opt/conda/conda-meta/pinned

RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
        gcc \
        libc-dev \
        libxslt-dev \
        libxml2-dev \
        libffi-dev \
        libssl-dev \
        zip \
        unzip \
        g++ \
        make \
        cmake \
        libcurl4-openssl-dev \
        libgtk2.0-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-cache search linux-headers-generic

RUN conda update -n base conda \
    && conda install -c conda-forge ffmpeg \
    && conda install -c pytorch pytorch torchvision cpuonly \
    && conda clean --all

ENV MODEL_URL http://moments.csail.mit.edu/moments_models/moments_RGB_resnet50_imagenetpretrained.pth.tar

RUN wget ${MODEL_URL} -o /tmp/model_weights

ARG FUNCTION_DIR

WORKDIR ${FUNCTION_DIR}
RUN mkdir -p ${FUNCTION_DIR}

COPY requirements.txt requirements.txt
RUN pip install --upgrade pip setuptools six \
    && pip install --target ${FUNCTION_DIR} --no-cache-dir -r requirements.txt

RUN mkdir lithops
COPY lithops_lambda.zip ${FUNCTION_DIR}
RUN unzip lithops_lambda.zip && rm lithops_lambda.zip

ENTRYPOINT [ "python", "-m", "awslambdaric" ]
CMD [ "__main__.lambda_handler" ]
